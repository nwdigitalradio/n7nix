#!/bin/bash
#
#  gps_util.sh
#
# This script:
#   - Display lat/lon in decimal degrees (aprx filters)
#     - dd.ddd format
#   - Display lat/lon in degrees, decimal minutes (aprx beacon)
#     - ddmm.mm/dddmm.mm format
#
# Some functions taken from aprx_install.sh
DEBUG=

scriptname="`basename $0`"

GPSPIPE="/usr/local/bin/gpspipe"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }


# ===== function set_canned_location
# Error handler for no gps found

function set_canned_location() {
    echo "Exiting, gps error"
    exit 1
}

# ===== function get_lat_lon_gpsdsentence

# Get gps lat/lon data in decimal degrees ie:
# Lat/Lon dd.ddd/(sign)ddd.dd format
# Used for aprx filters

function get_lat_lon_gpsdsentence() {
    # Read data from gps device, native gpsd sentences
    # Lat/Lon decimal degrees
    #  Latitude in dd.ddd format
    #  Longitude in (sign)ddd.ddd format

    gpsdata=$($GPSPIPE -w -n 10 | grep -m 1 lat | jq '.lat, .lon')

    # Separate lat & lon, store as decimal degrees
    latdd=$(echo $gpsdata | cut -d' ' -f1)
    londd=$(echo $gpsdata | cut -d' ' -f2)

    dbgecho "Decimal degrees: lat: $latdd, lon: $londd"

    # Convert to DD.DDD/(sign)DDD.DD (for APRX filters)

    latdd=$(printf "%05.3f" $latdd)
    londd=$(printf "%06.3f" $londd)

    dbgecho "Dec degrees: lat: $latdd, lon: $londd"
    return 0
}

# ===== function get_lat_lon_nmeasentence

# Get a GLL nmea sentence & convert to aprs format
# Get gps lat/lon in degrees, decimal minutes
# Lat/Lon ddmm.mm/dddmm.mm format
# Used for aprx beacon

function get_lat_lon_nmeasentence() {
    # Read data from gps device, nmea sentences
    # Latitude in ddmm.mmmm format.
    # Longitude in dddmm.mmmm format.
    gpsdata=$($GPSPIPE -r -n 15 | grep -m 1 -i gngll)

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

    # Convert lat/lon to DDMM.MM/DDDMM.MM (APRS format)

    lat=$(printf "%06.2f" $lat)
    lon=$(printf "%07.2f" $lon)

    # The syntax of the coordinates is APRS truncated form on NMEA
    # lat/lon form:
    #   lat ddmm.mmN
    #   lon dddmm.mmW
    dbgecho "lat: $lat$latdir, lon: $lon$londir"
    return 0
}

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
function is_gpsd() {

    retval=0
    # Verify gpsd is running
    journalctl --no-pager -u gpsd | tail -n 1 | grep -i error
    retcode="$?"
    if [ "$retcode" -eq 0 ] ; then
        echo "gpsd daemon is not running without errors."
        retval=1
    fi
    return $retval
}

# ===== function gpsd_status
# Check if gpsd has been installed
function gpsd_status() {
    dbgecho "gpsd_status"
    systemctl --no-pager status gpsd > /dev/null 2>&1
    return $?
}

# ===== function is_gps_sentence
# Check if gpsd is returning sentences
# Returns gps sentence count, should be 3
function is_gps_sentence() {
    dbgecho "is_gps_sentence"
    retval=$($GPSPIPE -r -n 3 -x 2 | grep -ic "class")
    return $retval
}

# ==== function verify_gps

function verify_gps() {
    # Verify gpsd is running OK
    is_gpsd
    if [ "$?" -ne 0 ] ; then
          exit 1
    fi
    # Verify gpsd is returning sentences
    is_gps_sentence
    result=$?
    echo "Verify gpsd is returning sentences: Sentence count: $result"

    if (( result > 0 )) ; then
        echo -n "Test nmea sentence: "
        get_lat_lon_nmeasentence
        if [ "$?" -ne 0 ] ; then
            echo "Invalid gps data read from gpsd"
        else
            echo "GPS nmea sentences OK"
        fi

        echo -n "Test gpsd sentence: "
        get_lat_lon_gpsdsentence
        if [ "$?" -ne 0 ] ; then
            echo "Invalid gps data read from gpsd"
        else
            echo "GPS gpsd sentences OK"
        fi
    else
        echo "gpsd is installed but not returning sentences."
    fi
}

# ===== function get_coordinates

# Get lat/lon co-ordinates in both:
#   - decimal degrees format
#   - degrees with decimal minutes
#
# If gps is not installed or not working co-ordinates then exit

function get_coordinates() {
    gps_running=false
    gps_status="Fail"

    # Check if a DRAWS card found & gpsd is installed
    # otherwise don't bother looking for gpspipe program

    if is_draws && is_gpsd && gpsd_status ; then
        dbgecho "Verify gpspipe is installed"
        # Check if program to get lat/lon info is installed.
        prog_name="$GPSPIPE"
        type -P $prog_name &> /dev/null
        if [ $? -ne 0 ] ; then

            # Don't do this as it will install a down rev version of /usr/bin/gpspipe
            # Need at least /usr/local/bin/gpspipe: 3.19 (revision 3.19)
            # echo "$scriptname: Installing gpsd-clients package"
            # sudo apt-get install gpsd-clients

            echo "Could not locate $prog_name ..."
            set_canned_location
            return 1
        fi

        # Verify gpsd is returning sentences
        is_gps_sentence
        result=$?
        dbgecho "Verify gpsd is returning sentences ret: $result"

        if (( result > 0 )) ; then
            gps_running=true

            # Get lat/lon in degrees with decimal minutes
            dbgecho "get nmea sentence"
            # Uses xxGLL
            # Latitude in DDmm.mmm format.
            # Longitude in DDDmm.mmm format.
            get_lat_lon_nmeasentence
            if [ "$?" -ne 0 ] ; then
                echo "Read Invalid gps data read from gpsd, using canned values"
                set_canned_location
            else
                gps_status="Ok"
            fi

            # Get lat/lon in decimal degrees
            dbgecho "get gpsd sentence"
            # Latitude in DD.DDD format.
            # Longitude in (sign)DDD.DDD format.
            get_lat_lon_gpsdsentence
        else
            echo "gpsd is installed but not returning sentences  ($result)."
            set_canned_location
        fi
        # Get 12V supply voltage
        batvoltage=$(sensors | grep -i "+12V:" | cut -d':' -f2 | sed -e 's/^[ \t]*//' | cut -d' ' -f1)
        dbgecho "Get 12V supply voltage: $batvoltage"
    else
        # gpsd not running or no DRAWS hat found
        echo "gpsd not running or no DRAWS hat found, using static lat/lon values"
        set_canned_location
        batvoltage=0
    fi
}


# ===== main

if [[ $# -gt 0 ]] ; then
    DEBUG=1
fi

verify_gps
get_coordinates
echo "Format: ddmm.mmmm: $lat $latdir/ $lon $londir"
echo "Format: dd.ddd: $latdd/$londd"
