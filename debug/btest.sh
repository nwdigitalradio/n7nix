#!/bin/bash
#
# btest.sh
# Added sequence number 7/1/2017
# Added choice of beacon types 10/12/2017
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
scriptname="`basename $0`"

BEACON="/usr/local/sbin/beacon"
CALLSIGN="NOONE"
ax25port=udr0
#ax25port=vhf0
SEQUENCE_FILE="/tmp/sequence.tmp"

# BEACON_TYPE choices:
#  mesg_beacon - message beacon
#  posit_beacon - position beacon
# Set default beacon
BEACON_TYPE="mesg_beacon"

# ===== function dbgecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function usage
function usage() {
   echo "Usage: $scriptname [-p][-m][-h]" >&2
   echo "   -p | --position  send a position beacon"
   echo "   -m | --message   send a message beacon"
   echo "   -h | --help      display this message"
   echo
}

# ===== main
# must run as root
if [[ $EUID -ne 0 ]]; then
  echo "*** Run as root ***" 2>&1
  exit 1
fi

# has the beacon program been installed
type -P $BEACON &>/dev/null
if [ $? -ne 0 ] ; then
   # Get here if beacon program NOT installed.
   echo "$scriptname: ax25tools not installed."
   exit 1
fi

# determine if axport exists
grepret=$(grep $ax25port /etc/ax25/axports)
if [ $? -ne 0 ]; then
    echo "$scriptname: **** ax25 port $ax25port does not exist"
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
      echo "$scriptname: need to edit this script with your CALLSIGN"
      exit 1
   fi
else
   CALLSIGN=$(grep -m 1 "^MYCALL" /etc/direwolf.conf | cut -d' ' -f2)
   CALLNOSID=$(echo $CALLSIGN | cut -d'-' -f1)
   dbgecho "direwolf: Callsign: $CALLSIGN used from config file"
fi

if [ "$CALLSIGN" = "NOONE" ] ; then
   echo "$scriptname: need to edit this script with your CALLSIGN"
   exit 1
fi

# parse command line options
# if there are no args default to out put a message beacon
if [[ $# -eq 0 ]] ; then
   BEACON_TYPE="mesg_beacon"
fi

# if there are any args then parse them
while [[ $# -gt 0 ]] ; do
   key="$1"

   case $key in
      -m|--message)
         echo "Send a message beacon"
	 BEACON_TYPE="mesg_beacon"
	 ;;
      -p|--position)
         echo "Send a position beacon"
	 BEACON_TYPE="posit_beacon"
	 ;;
      -h|--help)
         usage
	 exit 0
	 ;;
      *)
	echo "Unknown option: $key"
	usage
	exit 1
	;;
   esac
shift # past argument or value
done


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
# Separate out string of beacon_msg to learn why extra characters are
# appearing at end of string on APRS.fi
# eg: 0A<0x0f> [Invalid message packet]

if [ "$BEACON_TYPE" = "mesg_beacon" ] ; then
   beacon_msg=":$CALLPAD:$timestamp $CALLNOSID beacon test from host $(hostname) Seq: $seqnum"
else
   beacon_msg="!4829.06N/12254.12W-$timestamp, from $(hostname) Seq: $seqnum"
fi

echo " Sent \
 BEACON -c $CALLNOSID-11 -d 'APUDR1 via WIDE1-1' -l -s $ax25port "${beacon_msg}""
$BEACON -c $CALLNOSID-11 -d 'APUDR1 via WIDE1-1' -l -s $ax25port "${beacon_msg}"

# increment sequence number
((seqnum++))
echo $seqnum > $SEQUENCE_FILE

exit 0
