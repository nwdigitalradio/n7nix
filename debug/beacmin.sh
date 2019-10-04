#!/bin/bash
#
# beacmin.sh
#
# Minimal APRS beacon of position data from GPS
# If a GPS is not found then a canned position is beaconed.
#
# Uncomment this statement for debug echos
#DEBUG=1

SID=15
AX25PORT=udr0

scriptname="`basename $0`"
BEACON="/usr/local/sbin/beacon"
NULL_CALLSIGN="NOONE"
CALLSIGN="$NULL_CALLSIGN"
USER="$(whoami)"
TMPDIR="/home/$USER/tmp"
SEQUENCE_FILE="$TMPDIR/sequence.tmp"
AXPORTS_FILE="/etc/ax25/axports"

# boolean for using gpsd sentence instead of nmea sentence
b_gpsdsentence=false

# get_lat_lon_nmeasentence will set the following direction variables
# get_lat_long_gpsdsentence will not
latdir="N"
londir="W"

# ===== function dbgecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_draws
# Determine if a NWDR DRAWS hat is installed
function is_draws() {
    retval=1
    firmware_prod_idfile="/sys/firmware/devicetree/base/hat/product_id"
    UDRC_ID="$(tr -d '\0' < $firmware_prod_idfile)"
    #get last character in product id file
    UDRC_ID=${UDRC_ID: -1}
    if [ "$UDRC_ID" -eq 4 ] ; then
        retval=0
    fi
    return $retval
}

# ===== function is_gpsd
# Check if gpsd has been installed
function is_gpsd() {
    dbgecho "is_gpsd"
    systemctl --no-pager status gpsd > /dev/null 2>&1
    return $?
}

# ===== function is_gps_sentence
# Check if gpsd is returning sentences
# Returns gps sentence count, should be 3
function is_gps_sentence() {
    dbgecho "is_gps_sentence"
    retval=$(gpspipe -r -n 3 -x 2 | grep -ic "class")
    return $retval
}

# ===== function set_canned_location
function set_canned_location() {
    lat="4830.00"
    latdir="N"
    lon="12250.00"
    londir="W"
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
        echo "GPS data not valid"
        echo "gps data: $gpsdata"
       return 1
    fi

    dbgecho "gps data: $gpsdata"

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

# ===== function is_ax25up
function is_ax25up() {
  ip a show ax0 up > /dev/null  2>&1
}


# ===== main

if [[ $# -gt 0 ]] ; then
    echo "$scriptname: does NOT take any arguments."
fi

# Check if AX.25 port ax0 exists & is up
if ! is_ax25up ; then
    echo "$scriptname: AX.25 port not found, is AX.25 configured?"
    exit 1
fi

# Don't bother looking for gpspipe if gpsd is not installed

if is_gpsd && is_draws ; then
    # Check if program to get lat/lon info is installed.
    prog_name="gpspipe"
    type -P $prog_name &> /dev/null
    if [ $? -ne 0 ] ; then
        echo "$scriptname: Installing gpsd-clients package"
        sudo apt-get install gpsd-clients
    fi

    # Verify gpsd is returning sentences
    if [ $(is_gps_sentence) > 0 ] ; then
        gps_running=true
        # Choose between using gpsd sentences or nmea sentences
        if $b_gpsdsentence ; then
            prog_name="bc"
            type -P $prog_name &> /dev/null
            if [ $? -ne 0 ] ; then
                echo "$scriptname: Installing $prog_name package"
                sudo apt-get install -y -q $prog_name
            fi
        else
            # echo "nmea sentence"
            get_lat_lon_nmeasentence
            if [ "$?" -ne 0 ] ; then
                echo "Read Invalid gps data read from gpsd, using canned values"
                set_canned_location
            fi
        fi
    else
        dbgecho "gpsd is installed but not returning sentences."
    fi
else
    # gpsd not running or no DRAWS hat found
    echo "gpsd not running or no DRAWS hat found, using static lat/lon values"
    set_canned_location
fi

timestamp=$(date "+%d %T %Z")

seqnum=0

# Test if temporary directory for SEQUENCE_FILE exists
if [ ! -d "$TMPDIR" ] ; then
   dbgecho "Directory: $TMPDIR does not exist, making ..."
   mkdir -p "$TMPDIR"
fi

# get sequence number
if [ -e $SEQUENCE_FILE ] ; then
   seqnum=`cat $SEQUENCE_FILE`
else
   echo "0" > $SEQUENCE_FILE
fi

# Check if the callsign & ax25 port have been manually set
if [ "$CALLSIGN" = "$NULL_CALLSIGN" ] ; then
   callsign_axports
fi

# APRS icons
# /j = jeep, /k = pickup truck, /> = car, /s = boat
# /p = dog, /- = house, /i = tree on island

beacon_msg="!${lat}${latdir}/${lon}${londir}p$timestamp, Seq: $seqnum"

echo " Sent: \
$BEACON -c $CALLSIGN-$SID -d 'APUDR1 via WIDE1-1' -l -s $AX25PORT "${beacon_msg}""
if [ -z "$DEBUG" ] ; then
    $BEACON -c $CALLSIGN-$SID -d 'APUDR1 via WIDE1-1' -l -s $AX25PORT "${beacon_msg}"
    if [ "$?" -ne 0 ] ; then
        echo "Beacon command failed."
    fi
else
    echo "$scriptname: Debug set, beacon not actually sent."
fi
# increment sequence number
((seqnum++))
echo $seqnum > $SEQUENCE_FILE

exit 0
