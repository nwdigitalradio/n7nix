#!/bin/bash
#
# beacbloom.sh
#
# Minimal winlink beacon for Ed KD9FRQ
#
# crontab entry to beacon every 20 minutes
# */20 * * * * $HOME/bin/beacbloom.sh > /dev/null 2>&1

DEBUG=

NULL_CALLSIGN="NOONE"
CALLSIGN=$NULL_CALLSIGN

SID=4
BEACON="/usr/local/sbin/beacon"
AX25PORT=udr0
SEQUENCE_FILE="/tmp/sequence.tmp"
AXPORTS_FILE="/etc/ax25/axports"
seqnum=0

# ===== function dbgecho

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function callsign_axports

# Pull a call sign from the /etc/ax25/axports file
function callsign_axports () {
   linecnt=$(grep -vc '^#' $AXPORTS_FILE)
   if (( linecnt > 1 )) ; then
      dbgecho "axports: found $linecnt lines that are not comments"
   fi
   # Collapse all spaces on lines that do not begin with a comment
   getline=$(grep -v '^#' $AXPORTS_FILE | tr -s '[[:space:]] ')
   dbgecho "axports: found line: $getline"

   # Only set CALLSIGN or AX25PORT if they haven't already been set manually
   if [ "$CALLSIGN" = "$NULL_CALLSIGN" ] ; then
      CALLSIGN=$(echo $getline | cut -d ' ' -f2 | cut -d '-' -f1)
   fi
   if [ "$AX25PORT" = "NOPORT" ] ; then
      AX25PORT=$(echo $getline | cut -d ' ' -f1)
   fi
}

# ===== main

# parse command line options
# if there are any args set debug flag
if [[ $# -ne 0 ]] ; then
   DEBUG=1
fi

# Get ambient temperature IF available
AMB_TEMP=
which $HOME/bin/rpiamb_gettemp.sh
if [ $? -ne 1 ] ; then
    AMB_TEMP=$($HOME/bin/rpiamb_gettemp.sh)
fi

# Get data on RPi CPU
temp=$(vcgencmd measure_temp)
throt=$(vcgencmd get_throttled)
node_name=$(uname -n)

if [ -e $SEQUENCE_FILE ] ; then
   seqnum=`cat $SEQUENCE_FILE`
else
    echo "0" > $SEQUENCE_FILE
fi

callsign_axports
if [ -z $CALLSIGN ] || [ $CALLSIGN == $NULL_CALLSIGN ] ; then
    echo "ERROR setting callign."
    exit 1
else
    dbgecho "Using callsign: $CALLSIGN"
fi

if [ ! -z AMB_TEMP ] ; then
    beacon_msg="$CALLSIGN status of $node_name: ambient temp=$AMB_TEMP'F, cpu $temp, $throt Seq: $seqnum"
else
    beacon_msg="$CALLSIGN status of $node_name: cpu $temp, $throt Seq: $seqnum"
fi

if [ ! -z "$DEBUG" ] ; then
    echo "DEBUG flag set NO beacon will be transmitted."
    echo "Sent beacon $(date): -c $CALLSIGN-$SID -d 'BEACON' -l -s $AX25PORT ${beacon_msg}"
    exit
fi

#  -c  Configure  the  source  callsign for beacons. The default is to
#      use the interface call-sign.
#  -l  Enables the logging of errors to the system log, the default is off.
#  -d  Configure the destination callsign for beacons.  Default is 'IDENT'.
#  -s  Sends the message text once only


$BEACON -c $CALLSIGN-$SID -d 'BEACON' -l -s $AX25PORT "${beacon_msg}"

# increment sequence number
((seqnum++))
echo $seqnum > $SEQUENCE_FILE

echo "Sent beacon $(date): -c $CALLSIGN-$SID -d 'BEACON' -l -s $AX25PORT ${beacon_msg}" >> /tmp/aprsbeacon.log


