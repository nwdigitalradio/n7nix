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

NULL_CALLSIGN="NOONE"
CALLSIGN="$NULL_CALLSIGN"
AX25PORT="NOPORT"
SID="11"
verbose="false"
# boolean for using gpsd sentence instead of nmea sentence
b_gpsdsentence=false

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
   if [ "$CALLSIGN" = "$NULL_CALLSIGN" ] ; then
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
      if [ "$CALLSIGN" = "$NULL_CALLSIGN" ] ; then
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
   if [ "$CALLSIGN" = "$NULL_CALLSIGN" ] ; then
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

# ===== function get_lat_lon_nmeasentence
# Much easier to parse a nmea sentence &
# convert to aprs format than a gpsd sentence
function get_lat_lon_nmeasentence() {
    # Read data from gps device, nmea sentences
    gpsdata=$(gpspipe -r -n 15 | grep -m 1 -i gngll)

    # Get geographic gps position status
    ll_valid=$(echo $gpsdata | cut -d',' -f7)
    dbgecho "Status: $ll_valid"
    if [ "$ll_valid" != "A" ] ; then
        echo "GPS data not valid, exiting "
        echo "gps data: $gpsdata"
        return 1
    fi

    dbgecho "gpsdata: $gpsdata"

    # Separate lat, lon & position direction
    lat=$(echo $gpsdata | cut -d',' -f2)
    latdir=$(echo $gpsdata | cut -d',' -f3)
    lon=$(echo $gpsdata | cut -d',' -f4)
    londir=$(echo $gpsdata | cut -d',' -f5)

    dbgecho "lat: $lat$latdir, lon: $lon$londir"

    # Convert to legit APRS format
    lat=$(printf "%07.2f" $lat)
    lon=$(printf "%08.2f" $lon)

    dbgecho "lat: $lat$latdir, lon: $lon$londir"
    return 0
}

# ===== function get_lat_lon_gpsdsentence
# Only for reference, not used
# See get_lat_lon_nmeasentence
function get_lat_lon_gpsdsentence() {
    # Read data from gps device, gpsd sentences
    gpsdata=$(gpspipe -w -n 10 | grep -m 1 lat | jq '.lat, .lon')

    dbgecho "gpsdata: $gpsdata"

    # Separate lat & lon
    lat=$(echo $gpsdata | cut -d' ' -f1)
    lon=$(echo $gpsdata | cut -d' ' -f2)

    dbgecho "lat: $lat$latdir, lon: $lon$londir"

    # Separate latitude integer & decimal
    latint=${lat%%.*}
    latrat=${lat##*.}

    # Get rid of leading minus sign on longitude
    lon=${lon//[-_]/}
    # Separate longitude integer & decimal
    lonint=${lon%%.*}
    lonrat=${lon##*.}

    # Convert to APRS position format: Degrees Minutes.m
    latrat=$(echo ".$latrat*60" | bc)
    dbgecho "latrat: $latrat"
    lat=$(printf "%02i%05.2f" $latint $latrat)

    lonrat=$(echo ".$lonrat*60" | bc)
    dbgecho "lonrat: $lonrat"
    lon=$(printf "%03i%05.2f" $lonint $lonrat)
    dbgecho "lat: $lat, lon: $lon"
}

# ===== function usage
function usage() {
   echo "Usage: $scriptname [-P <port>][-s <num>][-p][-m][-v][-h]" >&2
   echo "   -P <portname> | --portname <portname>  eg. udr0"
   echo "   -s <num>      | --sid <num>  set sid in callsign, number 0-15"
   echo "   -p | --position  send a position beacon"
   echo "   -m | --message   send a message beacon (default)"
   echo "   -v | --verbose   display verbose messages"
   echo "   -h | --help      display this message"
   echo
}

# ===== main

# Check if running as root
if [[ $EUID -ne 0 ]]; then
  echo "*** Running as user: $(whoami) ***" 2>&1
#  exit 1
fi

# does the AXPORTS file exist ie. is ax.25 installed?
if [ ! -e $AXPORTS_FILE ] ; then
    echo "$scriptname: Couldn't locate ax25/axports file, is AX.25 installed?"
    exit 1
fi

# Has the beacon program been installed?
type -P $BEACON &>/dev/null
if [ $? -ne 0 ] ; then
   # Get here if beacon program NOT installed.
   echo "$scriptname: ax25tools not installed."
   exit 1
fi

# Check if program to get lat/lon info is installed.
prog_name="gpspipe"
type -P $prog_name &> /dev/null
if [ $? -ne 0 ] ; then
    echo "$scriptname: Installing gpsd-clients package"
    sudo apt-get install gpsd-clients
fi

# Choose between using gpsd sentences or nmea sentences
if $b_gpsdsentence ; then
    prog_name="bc"
    type -P $prog_name &> /dev/null
    if [ $? -ne 0 ] ; then
        echo "$scriptname: Installing $prog_name package"
        sudo apt-get install -y -q $prog_name
    fi
fi

seqnum=0
# get sequence number
if [ -e $SEQUENCE_FILE ] ; then
   seqnum=`cat $SEQUENCE_FILE`
fi

# Check if the callsign & ax25 port have been manually set
if [ "$CALLSIGN" = "$NULL_CALLSIGN" ] || [ "$AX25PORT" = "NOPORT" ] ; then
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
	 BEACON_TYPE="mesg_beacon"
	 ;;
      -P |--portname)
          AX25PORT="$2"
          shift  # past argument
         ;;
      -p|--position)
	 BEACON_TYPE="posit_beacon"
	 ;;
      -h|--help)
         usage
	 exit 0
	 ;;
      -s|--sid)
         SID="$2"
         shift
         ;;
      -v|--verbose)
         verbose="true"
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
    echo "Send a message beacon"
    beacon_msg=":$CALLPAD:$timestamp $CALLSIGN $BEACON_TYPE test from host $(hostname) on port $AX25PORT Seq: $seqnum"
else
    echo "Send a position beacon"
    get_lat_lon_nmeasentence
    if [ "$?" -ne 0 ] ; then
        echo "Invalid gps data"
#        exit 1
    fi

    beacon_msg="!${lat}N/${lon}W-$timestamp, from $(hostname) on port $AX25PORT Seq: $seqnum"
fi

if [ "$verbose" = "true" ] ; then
   echo "Callsign: $CALLSIGN-$SID, Port: $AX25PORT"
fi
echo " Sent: \
$BEACON -c $CALLSIGN-$SID -d 'APUDR1 via WIDE1-1' -l -s $AX25PORT "${beacon_msg}""
$BEACON -c $CALLSIGN-$SID -d 'APUDR1 via WIDE1-1' -l -s $AX25PORT "${beacon_msg}"
if [ "$?" -ne 0 ] ; then
    echo "Beacon command failed."
fi

# increment sequence number
sudo chown $(whoami):$(whoami) $SEQUENCE_FILE
((seqnum++))
echo $seqnum > $SEQUENCE_FILE

exit 0
