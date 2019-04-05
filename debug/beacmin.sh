#!/bin/bash
#
# beacmin.sh
#
# Minimal APRS beacon of position data from GPS
#
# Uncomment this statement for debug echos
#DEBUG=1

SID=15
AX25PORT=udr0

BEACON="/usr/local/sbin/beacon"
NULL_CALLSIGN="NOONE"
CALLSIGN="$NULL_CALLSIGN"
SEQUENCE_FILE="/home/pi/tmp/sequence.tmp"
AXPORTS_FILE="/etc/ax25/axports"


# ===== function dbgecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function get_lat_lon
function get_lat_lon() {
    # Read data from gps device
    gpsdata=$(gpspipe -w -n 10 | grep -m 1 lat | jq '.lat, .lon')
    linecnt=$(echo $gpsdata | wc -l)
    dbgecho "Read $linecnt lines of gps data"

    lat=$(echo $gpsdata | cut -d' ' -f1)
    lon=$(echo $gpsdata | cut -d' ' -f2)

    dbgecho "gpsdata: $gpsdata"

    # Separate lat & lon
    lat=$(echo $gpsdata | cut -d' ' -f1)
    lon=$(echo $gpsdata | cut -d' ' -f2)
    dbgecho "lat: $lat"
    dbgecho "lon: $lon"

    # Separate latitude integer & decimal
    latint=${lat%%.*}
    latrat=${lat##*.}

    # Get rid of leading minus sign on longitude
    lon=${lon//[-_]/}
    # Separate longitude integer & decimal
    lonint=${lon%%.*}
    lonrat=${lon##*.}

    # Convert to APRS position format: Degrees Minutes.m
    latrat=$((latrat*60))
    dbgecho "latrat: $latrat"
    lat=$latint${latrat:0:2}.${latrat:2:2}

    lonrat=$((lonrat*60))
    dbgecho "lonrat: $lonrat"
    lon=$lonint${lonrat:0:2}.${lonrat:2:2}
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

# ===== main

# Check if program to get lat/lon info is installed.
prog_name="gpspipe"
type -P $prog_name &> /dev/null
if [ $? -ne 0 ] ; then
    echo "$scriptname: Installing gpsd-clients package"
    sudo apt-get install -y -q gpsd-clients
fi

get_lat_lon

timestamp=$(date "+%d %T %Z")
beacon_msg="!${lat}N/${lon}W-$timestamp"

seqnum=0
# get sequence number
if [ -e $SEQUENCE_FILE ] ; then
   seqnum=`cat $SEQUENCE_FILE`
fi

# Check if the callsign & ax25 port have been manually set
if [ "$CALLSIGN" = "$NULL_CALLSIGN" ] ; then
   callsign_axports
fi

# APRS icons
# /j = jeep, /k = pickup truck, /> = car, /s = boat
# /p = dog, /- = house, /i = tree on island

beacon_msg="!${lat}N/${lon}Wp$timestamp, Seq: $seqnum"

echo " Sent: \
$BEACON -c $CALLSIGN-$SID -d 'APUDR1 via WIDE1-1' -l -s $AX25PORT "${beacon_msg}""
$BEACON -c $CALLSIGN-$SID -d 'APUDR1 via WIDE1-1' -l -s $AX25PORT "${beacon_msg}"
if [ "$?" -ne 0 ] ; then
    echo "Beacon command failed."
fi

# increment sequence number
((seqnum++))
echo $seqnum > $SEQUENCE_FILE
