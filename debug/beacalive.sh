#!/bin/bash
#
# beacbloom.sh
#
# Minimal winlink beacon for Ed KD9FRQ
#
# crontab entry to beacon every 20 minutes
# */20 * * * * $HOME/bin/beacbloom.sh > /dev/null 2>&1

CALLSIGN="N7NIX"
SID=15
BEACON="/usr/local/sbin/beacon"
AX25PORT=udr0
SEQUENCE_FILE="/tmp/sequence.tmp"

temp=$(vcgencmd measure_temp)
throt=$(vcgencmd get_throttled)
node_name=$(uname -n)

seqnum=0

if [ -e $SEQUENCE_FILE ] ; then
   seqnum=`cat $SEQUENCE_FILE`
else
    echo "0" > $SEQUENCE_FILE
fi

beacon_msg="$CALLSIGN status of $node_name: $temp, $throt Seq: $seqnum"

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


