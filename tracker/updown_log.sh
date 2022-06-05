#!/bin/bash
#
# Write an entry to a log file and APRS beacon voltage upon
#  start-up or shutdown
# Test voltage read from sensors to determine when running on battery
# only.
#
# Usage: updown_log.sh arg1
# arg1 = u - log startup
# arg1 = d - log shutdown
# arg1 = t - test log file entry
# arg1 = <nothing> default: test log file entry
#
# example crontab entries follows:
#
# First beacon after power up
# @reboot $HOME/tmp/updown_log.sh -u | at now + 1 minute
#
# First beacon after power up
# @reboot sleep 120 && $HOME/bin/updown_log.sh u
#
# Test down
#*/2  *  *  *  *  $HOME/bin/updown_log.sh d
#
# Test gps
# */10  *  *  *  *  $HOME/bin/updown_log.sh -g
#
# Uncomment this statement for debug echos
# DEBUG=1

USER="$(whoami)"
TMPDIR="/home/$USER/tmp"
LOGFILE="$TMPDIR/updown.log"
INPROGRESS_FILE="/tmp/shutdown_inprogress"
TRACKER_CONF_FILE="/etc/tracker/aprs_tracker.ini"

scriptname="`basename $0`"
BEACON="/usr/local/sbin/beacon"
GPSPIPE="/usr/local/bin/gpspipe"
NULL_CALLSIGN="NOONE"
CALLSIGN="$NULL_CALLSIGN"
STARTUP_WAIT=5
SHUTDOWN_WAIT=20

AXPORTS_FILE="/etc/ax25/axports"
SID=14
AX25PORT=udr0
sat_cnt=0
voltage=0

# ===== function dbgecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function sid_nixtracker
# Pull SSID from nixtracker /etc/tracker/aprs_tracker.ini file
function sid_nixtracker() {
    if [ -f "$TRACKER_CONF_FILE" ] ; then
        SID=$(grep -i "mycall = " "$TRACKER_CONF_FILE" | cut -f2 -d '=' | cut -d'-' -f2)
    fi
}

# ===== function callsign_axports
# Pull a call sign from the /etc/ax25/axports file
function callsign_axports () {
   # Collapse all spaces on lines that do not begin with a comment
   getline=$(grep -v '^#' $AXPORTS_FILE | tr -s '[[:space:]] ')
   dbgecho "axports: found line: $getline"

   # Only set CALLSIGN if has not already been set manually
   if [ "$CALLSIGN" = "$NULL_CALLSIGN" ] ; then
      cs_axports=$(echo $getline | cut -d ' ' -f2 | cut -d '-' -f1)
      dbgecho "Found callsign: $cs_axports"
      # Test if callsign string is not null
      if [ ! -z "$cs_axports" ] ; then
          CALLSIGN="$cs_axports"
          dbgecho "Set callsign $CALLSIGN"
      fi
   fi
}

# ===== function pad_callsign
function pad_callsign() {
# pad aprs Message format addressee field to 9 characters
    if (( ${#CALLSIGN} == 9 )) ; then
        echo "No padding required for Callsign -$CALLSIGN"
    else
        whitespace=""
        singlewhitespace=" "
        whitelen=`expr 9 - ${#CALLSIGN}`
        # echo " -- whitelen $whitelen, callsign $CALLSIGN callsign len ${#CALLSIGN}"

        for ((i=0; i < $whitelen; i++)) ; do
            whitespace=$(echo -n "$whitespace$singlewhitespace")
        done;
        CALLPAD="$CALLSIGN$whitespace"
    fi
}

# ===== function beacon_now
function beacon_now() {

    log_msg=":$CALLPAD:$timestamp $action, host $(hostname), port $AX25PORT, voltage: $voltage, sats: $sat_cnt"
    echo "$log_msg" | tee -a $LOGFILE
    sid_nixtracker

    if [ "$action" == "test" ] ; then
#$BEACON -c $CALLSIGN-$SID -d 'APUDR1 via WIDE1-1' -l -s $AX25PORT "$(printf "%s\0" "$log_msg")"" | tee -a $LOGFILE
        echo "Would send: \
$BEACON -c $CALLSIGN-$SID -d 'APUDR1 via WIDE1-1' -l -s $AX25PORT $log_msg" | tee -a $LOGFILE
    else
#        $BEACON -c $CALLSIGN-$SID -d 'APUDR1 via WIDE1-1' -l -s $AX25PORT "$(printf "%s\0" "$log_msg")" >> $LOGFILE 2>&1
        $BEACON -c $CALLSIGN-$SID -d 'APUDR1 via WIDE1-1' -l -s $AX25PORT "$log_msg" >> $LOGFILE 2>&1
    fi
}

# ===== function gga_satcount
# Get count of number of satelites in use
# The number returned here matches the number viewed when using cgps /Used
# Use this in the crontab beacon

function gga_satcount() {
    sat_cnt=$($GPSPIPE -r -n 30 | grep -m 1 -i gngga | cut -f8 -d',')
    # Remove any leading zeros
    sat_cnt=$((10#$sat_cnt))
}

# ===== Display program help info
usage () {
	(
	echo "Usage: $scriptname [-u][-d][-t][-h]"
        echo "            No args will just display beacon"
        echo "  -u        Log & beacon a start up event"
        echo "  -d        Log & beacon a shut down event"
        echo "  -g        Log & beacon a gps test event"
        echo "  -t        Test, no beacon just display beacon"
        echo "  -h        Display this message"
        echo
	) 1>&2
	exit 1
}

# ===== main

timestamp=$(date "+%Y %m %d %T %Z")
action="Nothing"

# Check that tmpdir exists

if [ ! -d "$TMPDIR" ] ; then
    mkdir -p $TMPDIR
fi

# get sensor voltage
voltage=$(sensors | grep -i "+12V:" | cut -d':' -f2 | sed -e 's/^[ \t]*//' | cut -d' ' -f1)

# get voltage withOUT plus sign or decimal
volt_int=$(echo "${voltage//[^0-9]/}")

# get a valid call sign
callsign_axports
# pad call sign length for APRS
pad_callsign

if [[ $# -gt 0 ]] ; then
    arg1=$1
    case $arg1 in
        -u|u)
            action="Startup"
            dbgecho "action: $action"

            sleep $STARTUP_WAIT
            gga_satcount
            beacon_now
        ;;
        -d|d)
            action="Shutdown"
            dbgecho "action: $action"

            # Has vehicle switched off & running on battery?
            if (( volt_int < 1300 )) ; then
                # Getting multiple shut down beacons, create a flag file
                if [ ! -e "$INPROGRESS_FILE" ] ; then
                    gga_satcount
                    beacon_now
                    touch $INPROGRESS_FILE
                    sleep $SHUTDOWN_WAIT
# smallest ITS-12 resolution is 2 minutes
# If ITS-12 is set to 1 then it will shut down in 15 minutes which is
#  too long.
# smallest shutdown resolution is 1 minute
#                  sudo /sbin/shutdown -h +1 "Shutting down in 1 minute"
                   sudo /sbin/shutdown -h now "Shutting down NOW"
               fi
            fi
        ;;
        -g|g)
            action="GPS_test"
            gga_satcount
            echo "action: $action, sats: $sat_cnt"

            beacon_now
        ;;
        -t|t)
            # log beacon test, display what log entry would look like without beaconing
            action="test"
            dbgecho "action: $action"
            gga_satcount
            beacon_now
        ;;
        -h)
            usage
            exit 0
        ;;

        *)
            echo "Undefined argument: $arg1"
            exit 1
        ;;
    esac
else
    # no arguments, display what log entry would look like without beaconing
    # Display voltage
    action="test"
    dbgecho "No args: $action"
    gga_satcount
    beacon_now
fi
exit 0
