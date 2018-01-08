#!/bin/bash
#
# btest.sh
#
# btest.sh [-m] [-p] [-h]
# -m Send a message beacon (default)
# -p Send a position beacon
# -h Display a usage message
#
# Added sequence number 7/1/2017
# Added choice of beacon types 10/12/2017
# Get callsign & ax25 port name from axports file 01/08/2018
#
# The following are the beacon command line options not this programs.
#
# beacon [-c <src_call>] [-d <dest_call>[digi ..]] [-l] [-m] [-s] [-t interval] [-v] port "message"
# -c source callsign
# -d destination callsign
# -l enable logging
# -s send message only once
# -t interval in minutes between messages
#
# Uncomment this statement for debug echos
# DEBUG=1

CALLSIGN="NOONE"
AX25PORT="NOPORT"
SID="11"

scriptname="`basename $0`"
BEACON="/usr/local/sbin/beacon"

SEQUENCE_FILE="/tmp/sequence.tmp"
AXPORTS_FILE="/etc/ax25/axports"
DIREWOLF_CFG_FILE="/etc/direwolf.conf"

# BEACON_TYPE choices:
#  mesg_beacon - message beacon
#  posit_beacon - position beacon
# Set default beacon
BEACON_TYPE="mesg_beacon"

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
   if [ "$CALLSIGN" = "NOONE" ] ; then
      CALLSIGN=$(echo $getline | cut -d ' ' -f2 | cut -d '-' -f1)
   fi
   if [ "$AX25PORT" = "NOPORT" ] ; then
      AX25PORT=$(echo $getline | cut -d ' ' -f1)
   fi
}

# ===== function callsign_direwolf
# Not used, left for reference only
# Pull a call sign from the direwolf config file
function callsign_direwolf() {
   if [ ! -e $DIREWOLF_CFG_FILE ] ; then
      dbgecho "Direwolf: NO config file found!!"
      if [ "$CALLSIGN" = "NOONE" ] ; then
         callsign_axports
         echo "$scriptname: call sign from axports"
      fi
   else
      CALLSIGN=$(grep -m 1 "^MYCALL" $DIREWOLF_CFG_FILE | cut -d' ' -f2)
      # Chop off the SID
      CALLSIGN=$(echo $CALLSIGN | cut -d'-' -f1)
      dbgecho "direwolf: Callsign: $CALLSIGN used from config file"
   fi
}

# ===== function callsign_verify
function callsign_verify() {
   if [ "$CALLSIGN" = "NOONE" ] ; then
      echo "$scriptname: need to edit this script with your CALLSIGN"
      exit 1
   fi

   if [ "$AX25PORT" = "NOPORT" ] ; then
      echo "$scriptname: need to edit this script with your AX.25 port"
      exit 1
   fi

   # determine if ax.25 port name exists
   grepret=$(grep $AX25PORT $AXPORTS_FILE)
   if [ $? -ne 0 ]; then
       echo "$scriptname: **** ax25 port $AX25PORT does not exist"
       exit 1
   fi

   dbgecho "Using callsign $CALLSIGN & port $AX25PORT"
}

# ===== function usage
function usage() {
   echo "Usage: $scriptname [-p][-m][-h]" >&2
   echo "   -p | --position  send a position beacon"
   echo "   -m | --message   send a message beacon (default)"
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

seqnum=0
# get sequence number
if [ -e $SEQUENCE_FILE ] ; then
   seqnum=`cat $SEQUENCE_FILE`
fi

# Check if the callsign & ax25 port have been manually set
if [ "$CALLSIGN" = "NOONE" ] || [ "$AX25PORT" = "NOPORT" ] ; then
   callsign_axports
fi
callsign_verify

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
   beacon_msg=":$CALLPAD:$timestamp $CALLSIGN beacon test from host $(hostname) Seq: $seqnum"
else
   beacon_msg="!4829.06N/12254.12W-$timestamp, from $(hostname) Seq: $seqnum"
fi

echo " Sent \
 BEACON -c $CALLSIGN-$SID -d 'APUDR1 via WIDE1-1' -l -s $AX25PORT "${beacon_msg}""
$BEACON -c $CALLSIGN-$SID -d 'APUDR1 via WIDE1-1' -l -s $AX25PORT "${beacon_msg}"

# increment sequence number
((seqnum++))
echo $seqnum > $SEQUENCE_FILE

exit 0
