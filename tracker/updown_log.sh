#!/bin/bash
#
# Write an entry to a log file and APRS beacon voltage upon
#  start-up or shutdown
# Test voltage read from sensors to determine when running on battery
# only.
#
# Usage: log_updown.sh arg1
# arg1 = u - log startup
# arg1 = d - log shutdown
# arg1 = t - test log file entry
# arg1 = <nothing> default: test log file entry
#
# crontab entry
# @reboot /home/pi/tmp/updown_log.sh u
#*/2  *  *  *  *  /home/pi/tmp/updown_log.sh d
#
# Uncomment this statement for debug echos
DEBUG=1

USER="$(whoami)"
TMPDIR="/home/$USER/tmp"
LOGFILE="$TMPDIR/updown.log"
INPROGRESS_FILE="/tmp/shutdown_inprogress"

scriptname="`basename $0`"
BEACON="/usr/local/sbin/beacon"
NULL_CALLSIGN="NOONE"
CALLSIGN="$NULL_CALLSIGN"
STARTUP_WAIT=5
SHUTDOWN_WAIT=20

AXPORTS_FILE="/etc/ax25/axports"
SID=14
AX25PORT=udr0

# ===== function dbgecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function sid_nixtracker
# Pull SSID from nixtracker /etc/tracker/aprs_tracker.ini file
function sid_nixtracker() {
    SID=$(grep -i "mycall = " /etc/tracker/aprs_tracker.ini | cut -f2 -d '=' | cut -d'-' -f2)
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

    log_msg=":$CALLPAD:$timestamp $action, host $(hostname), port $AX25PORT, voltage: $voltage"
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
            beacon_now
        ;;
        -d|d)
            action="Shutdown"
            dbgecho "action: $action"

            # Has vehicle switched off & running on battery?
            if (( volt_int < 1300 )) ; then
                # Getting multiple shut down beacons, create a flag file
                if [ ! -e "$INPROGRESS_FILE" ] ; then
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
        -t|t)
            # log beacon test, display what log entry would look like without beaconing
            action="test"
            dbgecho "action: $action"

            beacon_now
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

    beacon_now
fi
exit 0
