#!/bin/bash
#
# btest.sh
# Added sequence number 7/1/2017
#
# beacon options
# -c source callsign
# -d destination callsign
# -l enable logging
# -s send message only once
# -t interval in minutes between messages
#
# beacon [-c <src_call>] [-d <dest_call>[digi ..]] [-l] [-m] [-s] [-t interval] [-v] port "message"
# Uncomment this statement for debug echos
DEBUG=1
myname="`basename $0`"

BEACON="/usr/local/sbin/beacon"
CALLSIGN="NOONE"
ax25port=udr0
#ax25port=vhf0
SEQUENCE_FILE="sequence.tmp"

# ===== function dbgecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== main
# must run as root
if [[ $EUID -ne 0 ]]; then
  echo "*** Run as root ***" 2>&1
  exit 1
fi

# has the beacon program been installed
type -P beacon &>/dev/null
if [ $? -ne 0 ] ; then
   # Get here if beacon program NOT installed.
   echo "$myname: ax25tools not installed."
   exit 1
fi

# determine if axport exists
grepret=$(grep $ax25port /etc/ax25/axports)
if [ $? -ne 0 ]; then
    echo "$myname: **** ax25 port $ax25port does not exist"
    exit 1
fi

seqnum=0
# get sequence number
if [ -e $SEQUENCE_FILE ] ; then
   seqnum=`cat $SEQUENCE_FILE`
fi

if [ ! -e /etc/direwolf.conf ] ; then
   dbgecho "Direwolf: NO config file found!!"
   if [ "$CALLSIGN" = "NOONE" ] ; then
      echo "$myname: need to edit this script with your CALLSIGN"
      exit 1
   fi
else
   CALLSIGN=$(grep -m 1 "^MYCALL" /etc/direwolf.conf | cut -d' ' -f2)
   CALLNOSID=$(echo $CALLSIGN | cut -d'-' -f1)
   dbgecho "direwolf: Callsign: $CALLSIGN used from config file"
fi

if [ "$CALLSIGN" = "NOONE" ] ; then
   echo "$myname: need to edit this script with your CALLSIGN"
   exit 1
fi

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

timestamp=$(date "+%d %T %Z")

# ; object

echo " Sent \
 BEACON -c $CALLNOSID-11 -d 'APUDR1 via WIDE1-1' -l -s $ax25port :$CALLPAD:$timestamp $CALLNOSID beacon test from host $(hostname) Seq: $seqnum"
$BEACON -c $CALLNOSID-11 -d 'APUDR1 via WIDE1-1' -l -s $ax25port ":$CALLPAD:$timestamp $CALLNOSID beacon test from host $(hostname) Seq: $seqnum"

# increment sequence number
((seqnum++))
echo $seqnum > $SEQUENCE_FILE

exit 0
