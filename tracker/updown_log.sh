#!/bin/bash
#
# Write an entry to a log file upon start-up or shutdown
# log_updown arg1
# arg1 = u - log startup
# arg1 = d - log shutdown
#
# Uncomment this statement for debug echos
#DEBUG=1

scriptname="`basename $0`"
BEACON="/usr/local/sbin/beacon"
NULL_CALLSIGN="NOONE"
CALLSIGN="$NULL_CALLSIGN"

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

# ===== main

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
            log_msg="$(date "+%Y %m %d %T %Z"): startup $voltage"
        ;;
        d)
            # log shutdown
            log_msg="$(date "+%Y %m %d %T %Z"): shutdown $voltage"
        ;;
        *)
            echo "Undefined argument: $arg1"
            exit 1
        ;;
    esac
else
    # no arguments, display what log entry would look like
    # Display voltage

    log_msg="$(date "+%Y %m %d %T %Z"): test $voltage"
fi

echo "$log_msg" | tee -a $LOGFILE

$BEACON -c $CALLSIGN-$SID -d 'APUDR1 via WIDE1-1' -l -s $AX25PORT "${log_msg}"