#!/bin/bash
#
# rmslist.sh <integer_distance_in_miles> <maidenhead_grid_square>
#
# Interrogate Winlink web services
# requires curl & jq
#
# jq JSON parser is in these Debian distros:
#    wheezy-backports, jessie & stretch
# If you need to download it get it from here:
# http://stedolan.github.io/jq/download/
#
# Winlink WEB services
#  GatewayStatus -> GatewayStatusRecord  -> GatewayOperatingMode
#  GatewayStatus -> GatewayChannelRecord -> Frequency
#  GatewayStatus -> GatewayChannelRecord -> Gridsquare
#
#  GatewayListing -> ListingType
#  GatewayProximity
#
DEBUG=

# paclink-unix web services key
PL_KEY="43137F63FDBA4F3FBEEBA007EB1ED348"

# Number of hours after which local file will be re-created.
STALE_HOURS=50
do_it_flag=false
silent=false

myname="`basename $0`"

#TMPDIR="/tmp"
TMPDIR="$HOME/tmp/ardop"

WINLINK_SERVICE="proximity"
ARDOP_FILE_RAW=
ARDOP_PROXIMITY_FILE_OUT="$TMPDIR/ardopprox.txt"
ARDOP_STATUS_FILE_OUT="$TMPDIR/ardopstatus.txt"
ARDOP_LIST_FILE_OUT="$TMPDIR/ardoplist.txt"

PKG_REQUIRE="jq curl"

max_distance=140        # default max distance of ARDOP RMS Gateways
include_history=48     # default number of history hours
grid_square="cn88nl"   # default grid square location or origin

# grid square location for Lopez Island, WA
# grid square location for 414 N Prom, Seaside, OR 97138
# grid_square="cn85ax"

## ============ functions ============

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {
   return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed")
}

# ===== function generate post data for curl call

function generate_post_data() {
cat <<EOF
{"GridSquare":"$grid_square","HistoryHours": $include_history,"MaxDistance": $max_distance}
EOF
}

# ===== function parse_status
# parse json data returned from a /gateway/status Winlink service call

function parse_status() {

dbgecho "Function parse_status"

callsign_cnt=0
freq_cnt=0

if $silent ; then

    # iterate through the JSON parsed file
    for k in $(jq '.GatewayList | keys | .[]' $ARDOP_FILE_RAW); do
        value=$(jq -r ".GatewayList[$k]" $ARDOP_FILE_RAW);

        callsign=$(jq -r '.Callsign' <<< $value);
        callsign=$(echo "$callsign" | tr -d ' ')
        frequency=$(jq -r '.Frequency' <<< $value);
        baud=$(jq -r '.Baud' <<< $value);
        distance=$(jq -r '.Distance' <<< $value);

        printf ' %-10s\t%10s\t%s\t%4s\n' "$callsign" "$frequency" "$distance" "$baud"
    done 2>&1 > $ARDOP_PROXIMITY_FILE_OUT

else

    # Print the table header
    echo "  Callsign       Frequency    Baud     Grid   Distance"

    # iterate through the JSON parsed file
    gateway_callsign=$(jq '.Gateways | keys | .[]' $ARDOP_FILE_RAW)
    for k in $(echo "$gateway_callsign"); do
        value=$(jq -r ".Gateways[$k]" $ARDOP_FILE_RAW);

        callsign=$(jq -r '.Callsign' <<< $value);
        callsign=$(echo "$callsign" | tr -d ' ')

        lat=$(jq -r '.Latitude' <<< $value);
        lon=$(jq -r '.Longitude' <<< $value);
        frequency=$(jq -r '.GatewayChannels[0].Frequency' <<< $value);
        baud=$(jq -r '.GatewayChannels[0].Baud' <<< $value);

#        echo "Test lat: $lat, lon: $lon, baud: $baud"
        # This loop iterates through a call signs frequency array
        gateway_channels=$(jq -c '.GatewayChannels[]' <<< $value)

#        jq -c '.GatewayChannels[]' <<< $value | while read i; do
        while read i; do
            frequency=$(jq -r '.Frequency' <<< $i);
            baud=$(jq -r '.Baud' <<< $i);
            gridsquare=$(jq -r '.Gridsquare' <<< $i);
            # Distance extraction does not work
            distance=$(jq -r '.Distance' <<< $value);
            # Count number of ardop frequencies for each call sign
            ((freq_cnt++))

#            if (( callsign_cnt < 10 )) ; then
                printf ' %-10s\t%10s\t%4s\t%6s\t%s\t%d\t%d\n' "$callsign" "$frequency" "$baud" "$gridsquare" $distance $callsign_cnt $freq_cnt
#            fi
 #       done
         done <<< $gateway_channels

        # Count number of unique call signs
        ((callsign_cnt++))

    done > >(tee $ARDOP_STATUS_FILE_OUT) 2>&1

    sleep .5 # to let tee catch up
    echo "Total ardop gateways: $callsign_cnt, frequency count: $freq_cnt"
fi
}

# ===== function parse_proximity
# parse json data returned from a /gateway/proximity Winlink service call
## All output goes to file so that nothing runs in a subshell & the
# counters work.

## function parse_proximity /gateway/proximity

function parse_proximity() {

    # Initialize output line count
    linecnt=0
    dbgecho " "
    dbgecho "Function parse_proximity with input file $ARDOP_FILE_RAW"

    # Print the table header
    echo " Callsign        Frequency  Distance    Baud"

    last_callsign="N0ONE"
    callsign_cnt=0
    # iterate through the JSON input file

#    gateway_list=$(jq '.GatewayList[] | keys | .[]' $ARDOP_FILE_RAW)
#    for k in $(echo "$gateway_list"); do

    for k in $(jq '.GatewayList | keys | .[]' $ARDOP_FILE_RAW); do
        value=$(jq -r ".GatewayList[$k]" $ARDOP_FILE_RAW);

        callsign=$(jq -r '.Callsign' <<< $value);
        callsign=$(echo "$callsign" | tr -d ' ')


        frequency=$(jq -r '.Frequency' <<< $value);
        mode=$(jq -r '.RequestedMode' <<< $value);
        baud=$(jq -r '.Baud' <<< $value);
        distance=$(jq -r '.Distance' <<< $value);

        if [ "$last_callsign" != "$callsign" ] ; then
            # Count number of unique call signs
            ((callsign_cnt++))
            last_callsign="$callsign"
        fi
        ((linecnt++))

        printf ' %-10s\t%10s\t%s\t%4s\n' "$callsign" "$frequency" "$distance" "$baud"

    done > >(tee $ARDOP_PROXIMITY_FILE_OUT) 2>&1

    sleep .5 # to let tee catch up
    echo "Total gateways: $linecnt, total call signs: $callsign_cnt"
}

# ==== function parse_listing /gateway/listing

function parse_listing() {
    dbgecho " "
    dbgecho "Function parse_proximity with input file $ARDOP_FILE_RAW"
    echo "Not implemented"
}

# ===== Display program help info
#
usage () {
	(
	echo "Usage: $scriptname [-s <winlink_service_name][-d][-f][-h][-D <distance][-g <grid_square>]"
        echo "                       Default to display Winlink PROXIMITY service."
        echo "  -D <distance>        Set distance in miles"
        echo "  -g <grid_square>     Set location grid square ie. CN88nl"
        echo "  -s <winlink_service> Specify Winlink service,: status, proximity or listing"
        echo "  -f                   Force update of service file"
        echo "  -d                   Set DEBUG flag"
        echo "  -h                   Display this message."
        echo
	) 1>&2
	exit 1
}

## =============== main ===============

# Get command line arguments
while [[ $# -gt 0 ]] ; do

    key="$1"
    case $key in
        -d)
            DEBUG=1
        ;;
        -D)
            # Set maximum distance for proximity service
            max_distance="$2"
            shift # past argument
            do_it_flag=true
        ;;
        -f)
            do_it_flag=true
        ;;
        -g)
            # Set Grid Square
            if [[ "$2" =~ [^a-zA-Z0-9] ]]; then
                echo "Invalid grid square ($2) using default $grid_square"
            else
                grid_square=$2
                # Convert grid square to upper case
                grid_square=$(echo "$grid_square" | tr '[a-z]' '[A-Z]')

                do_it_flag=true
           fi
           shift # past argument
        ;;
        -s)
            # Get winlink service

            WINLINK_SERVICE="$2"
            shift # past argument

            if [ "$WINLINK_SERVICE" != "status" ] && [ "$WINLINK_SERVICE" != "proximity" ] && [ "$WINLINK_SERVICE" != "listing" ] ; then
                echo "Service argument must be status, proximity or listing, found '$WINLINK_SERVICE"
                exit
            fi
            echo "Set service to: $WINLINK_SERVICE"
        ;;
        -h)
            usage
            exit 0
        ;;
        *)
            echo "Undefined argument: $key"
            usage
            exit 1
        ;;
    esac
    shift # past argument or value
done

# Are required programs installed?

# check if packages are installed
dbgecho "Check packages: $PKG_REQUIRE"
needs_pkg=false

for pkg_name in `echo ${PKG_REQUIRE}` ; do

   is_pkg_installed $pkg_name
   if [ $? -eq 0 ] ; then
      echo "$myname: Will Install $pkg_name program"
      needs_pkg=true
      break
   fi
done

if [ "$needs_pkg" = "true" ] ; then

   # Be sure we're running as root
   if [[ $EUID != 0 ]] ; then
      echo "Must be root to install packages"
      exit 1
   fi

   apt-get install -y -q $PKG_REQUIRE
   if [ "$?" -ne 0 ] ; then
      echo "Required package install failed. Please try this command manually:"
      echo "apt-get install -y $PKG_REQUIRE"
      exit 1
   fi
fi


if [ "$WINLINK_SERVICE" == "proximity" ] ; then
    ARDOP_FILE_RAW="$TMPDIR/ardopprox.json"
    svc_url="https://api.winlink.org/gateway/proximity?&Key=$PL_KEY&OperatingMode=ardop&Gridsquare=CN88nl&MaxDistance=$max_distance&format=json"

elif [ "$WINLINK_SERVICE" == "status" ] ; then
    ARDOP_FILE_RAW="$TMPDIR/ardopstatus.json"
    svc_url="https://api.winlink.org/gateway/status?&Mode=ardop&Key=$PL_KEY&format=json"

elif [ "$WINLINK_SERVICE" == "listing" ] ; then
    ARDOP_FILE_RAW="$TMPDIR/ardoplist.json"
    svc_url="https://api.winlink.org/gateway/listing?&ListingType=ardop&Key=$PL_KEY&format=json"
else
    echo "Winlink service $WINLINK_SERVICE not recognized."
    exit
fi

# Test if temporary directory exists
if [ ! -d "$TMPDIR" ] ; then
    mkdir -p "$TMPDIR"
fi

#  Test if temporary proximity file already exists
if [ ! -e "$ARDOP_FILE_RAW" ] ; then
    dbgecho "Set do_it flag"
    do_it_flag=true

else # Do this, output file exists

    # Determine how old the tmp file is
    dbgecho "Determine how old current file is, stale criteria: $STALE_HOURS hours"

  current_epoch=$(date "+%s")
  file_epoch=$(stat -c %Y $ARDOP_FILE_RAW)
  elapsed_time=$((current_epoch - file_epoch))
  elapsed_hours=$((elapsed_time / 3600))

if ! $silent ; then
    echo "$ARDOP_FILE_RAW file is: $elapsed_hours hours $((($elapsed_time % 3600)/60)) minute(s), $((elapsed_time % 60)) seconds old"
fi

# Only refresh the proximity file every day or so
  if ((elapsed_hours > STALE_HOURS)) ; then
    do_it_flag=true
  fi
fi # END Test if temporary proximity file already exists


curlret=0
# temporary - disable Winlink web services interrogation for testing $PROXIMITY_FILE_PARSE
# do_it_flag=false

if $do_it_flag ; then
    # Get the proximity information from the winlink server
    if ! $silent ; then
        echo "Using distance of $max_distance miles & grid square $grid_square"
        echo
    fi
    dbgecho "Using URL: $svc_url"

    curl -s -d "$(generate_post_data)" "$svc_url" > $ARDOP_FILE_RAW
    curlret="$?"

    echo "Generated new $ARDOP_FILE_RAW file"
    echo

else
    # Display the information in the previously created proximity file
    echo "Using existing proximity file"
    echo
fi

if [ "$curlret" -ne 0 ] ; then
    dbgecho "cURL return code: $curlret"
    if [ ! -z $DEBUG ] ; then
        echo "Dump raw proxmity json file"
        cat $ARDOP_FILE_RAW
    fi
#    echo
#    cat $ARDOP_FILE_RAW | jq '.ResponseStatus | {ErrorCode, Message}'
    js_errorcode=$(cat $ARDOP_FILE_RAW | jq '.ResponseStatus.ErrorCode')
    js_errormsg=$(cat $ARDOP_FILE_RAW | jq '.ResponseStatus.Message')
    echo
    echo "Debug: Error code: $js_errorcode, Error message: $js_errormsg"
    exit 1
fi

js_errorcode=$(cat $ARDOP_FILE_RAW | jq '.ResponseStatus.ErrorCode')

if [ "$js_errorcode" != "null" ] ; then
#    cat $ARDOP_FILE_RAW | jq '.ResponseStatus | {ErrorCode, Message}'
    js_errormsg=$(cat $ARDOP_FILE_RAW | jq '.ResponseStatus.Message')
    echo
    echo "Debug: Error code: $js_errorcode, Error message: $js_errormsg"
    exit 1
fi

dbgecho "Have good request json"

# Parse the JSON file
# cat $ARDOP_FILE_RAW | jq '.GatewayList[] | {Callsign, Frequency, Distance}' > $ARDOP_PROXIMITY_FILE_PARSE

if [ "$WINLINK_SERVICE" == "proximity" ] ; then
    parse_proximity

elif [ "$WINLINK_SERVICE" == "status" ] ; then
    parse_status

elif [ "$WINLINK_SERVICE" == "listing" ] ; then
    parse_listing
else
    echo "Winlink service $WINLINK_SERVICE not recognized."
    exit
fi

exit 0
