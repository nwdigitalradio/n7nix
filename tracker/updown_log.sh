#!/bin/bash
#
# Write an entry to a log file upon start-up or shutdown
# log_updown arg1
# arg1 = u - log startup
# arg1 = d - log shutdown
#
# crontab entry
# @reboot /home/pi/tmp/updown_log.sh u
#*/2  *  *  *  *  /home/pi/tmp/updown_log.sh d
#
# Uncomment this statement for debug echos
#DEBUG=1

scriptname="`basename $0`"
BEACON="/usr/local/sbin/beacon"
NULL_CALLSIGN="NOONE"
CALLSIGN="$NULL_CALLSIGN"
#CALLSIGN="N7NIX-14"

AXPORTS_FILE="/etc/ax25/axports"
SID=12
AX25PORT=udr0

USER="$(whoami)"
TMPDIR="/home/$USER/tmp"
LOGFILE=$TMPDIR/updown.log

# ===== function dbgecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

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
#      echo " -- whitelen $whitelen, callsign $CALLSIGN callsign len ${#CALLSIGN}"

      for ((i=0; i < $whitelen; i++)) ; do
        whitespace=$(echo -n "$whitespace$singlewhitespace")
      done;
      CALLPAD="$CALLSIGN$whitespace"
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

if [[ $# -gt 0 ]] ; then
    arg1=$1
    case $arg1 in
        u)
            # log startup
            callsign_axports
            pad_callsign
            action="Startup"
#            log_msg="$timestamp: startup $voltage"
        ;;
        d)
            # log shutdown
            callsign_axports
            pad_callsign
            action="Shutdown"
#            log_msg="$timestamp: shutdown $voltage"
            CALLSIGN="$NULL_CALLSIGN"

        ;;
        *)
            echo "Undefined argument: $arg1"
            exit 1
        ;;
    esac
else
    # no arguments, display what log entry would look like
    # Display voltage

#    log_msg="$(date "+%Y %m %d %T %Z"): test $voltage"
    action="Test"
    CALLSIGN="$NULL_CALLSIGN"
fi

log_msg=":$CALLPAD:$timestamp $action, host $(hostname), port $AX25PORT, voltage: $voltage"

echo "$log_msg" | tee -a $LOGFILE

if [ "$CALLSIGN" != "$NULL_CALLSIGN" ] ; then
    $BEACON -c $CALLSIGN-$SID -d 'APUDR1 via WIDE1-1' -l -s $AX25PORT "${log_msg}"
fi
