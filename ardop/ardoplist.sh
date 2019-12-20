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
DEBUG=1
# paclink-unix web services key
PL_KEY="43137F63FDBA4F3FBEEBA007EB1ED348"

# Number of hours after which local file will be re-created.
STALE_HOURS=50
do_it_flag=false
silent=false

myname="`basename $0`"

#TMPDIR="/tmp"
TMPDIR="$HOME/tmp/ardop"

ARDOP_FILE_RAW="$TMPDIR/ardopprox.json"
#ARDOP_FILE_RAW="$TMPDIR/ardoplist.json"
#ARDOP_FILE_RAW="$TMPDIR/ardopstatus.json"

ARDOP_PROXIMITY_FILE_OUT="$TMPDIR/ardopprox.txt"
PKG_REQUIRE="jq curl"

max_distance=30        # default max distance of RMS Gateways
include_history=48     # default number of history hours
grid_square="cn88nl"   # default grid square location or origin

# grid square location for Lopez Island, WA
# grid square location for 414 N Prom, Seaside, OR 97138
# grid_square="cn85ax"

## ============ functions ============

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }
#
# Display program help info
#
usage () {
	(
	echo "Usage: $0 <integer_distance_in_miles> <maidenhead_grid_square>"
	echo " exiting ..."
	) 1>&2
	exit 2
}

# is_pkg_installed

function is_pkg_installed() {
   return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed")
}

#
## function generate post data for curl call
#
function generate_post_data() {
cat <<EOF
{"GridSquare":"$grid_square","HistoryHours": $include_history,"MaxDistance": $max_distance}
EOF
}


## function parse_proximity /gateway/proximity
## All output goes to file so that nothing runs in a subshell & the
# counters work.
function parse_proximity() {

dbgecho "Function parse_proximity"

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


#    done 2>&1 | tee $ARDOP_PROXIMITY_FILE_OUT
    done 2>&1> $ARDOP_PROXIMITY_FILE_OUT
    echo "Total ardop gateways: $callsign_cnt, frequency count: $freq_cnt"

fi
}

## function parse_status /gateway/status


function parse_status() {

    # Initialize output line count
    linecnt=0
    ardopcnt=0
    dbgecho "Function parse_status"
    # Print the table header
    echo "  Callsign       Mode  Distance    Baud"

    # iterate through the JSON parsed file
    for k in $(jq '.Gateways | keys | .[]' $ARDOP_FILE_RAW); do
        value=$(jq -r ".Gateways[$k]" $ARDOP_FILE_RAW);
        echo "Value: $value"

        callsign=$(jq -r '.Callsign' <<< $value);
        callsign=$(echo "$callsign" | tr -d ' ')
#        frequency=$(jq -r '.Frequency' <<< $value);
#        mode=$(jq -r '.RequestedMode' <<< $value);
#        baud=$(jq -r '.Baud' <<< $value);
        distance=$(jq -r '.Distance' <<< $value);

#            array=$(jq -c -r ".GatewayChannels[] | to_entries " <<< $value);
            array=$(jq -c -r ".GatewayChannels[]" <<< $value);
            echo "array: $array"
            echo "$(jq -r '.GatewayChannels[0] | "\(.SupportedModes) , \(.Frequency)"' <<< $value)"
            echo "$(jq -r '.GatewayChannels[] | "\(.SupportedModes) , \(.Frequency)"' <<< $value)"

#         for row in $(echo "${sample}" | jq -r '.[] | @base64'); do
         for radio in $(jq -r -c '.GatewayChannels[]' <<< $value); do
             echo "radio: $radio"
#             echo "$(jq -r '.[] | "\(.SupportedModes) , \(.Frequency)"' <<< $array)"
             echo "$(jq -r '.[] | "\(.SupportedModes))"' <<< $array)"


#             mode=$(jq -r '.SupportedModes' <<< $array);
#            baud=$(jq -r '.Baud' <<< $array);
#             frequency=$(jq -r '.Frequency' <<< $array);

            echo "Mode: $mode, Frequency: $frequency, line: $linecnt"
            ((linecnt++))

            exit

if [ 1 -eq 0 ] ; then
            if (( linecnt < 5 )) ; then
#                printf ' %-10s\t%10s\t%s\t%4s\n' "$callsign" "$mode" "$distance" "$baud"
                 printf ' %-10s\n' "$frequency"
            else
                break;
            fi
            if [ "$mode" != "Packet" ] ; then
                ((ardopcnt++))
            fi
fi
        done
        exit
    done 2>&1
    echo "Total gateways: $linecnt, NOT packet: $ardopcnt"
}



## =============== main ===============

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

# Check for any command line arguments

if (( $# > 0 )) && [ -n "$1" ] ; then

  # Have an argument, check if it's numeric
  if (( $1 > 0 )) ; then
    max_distance=$1
    do_it_flag=true

  else
    echo "$0: arg ($1) invalid distance"
    usage
  fi
fi


# check for a second command line argument - grid square

if (( $# >= 2 )) ; then
  if [[ "$2" =~ [^a-zA-Z0-9] ]]; then
     echo "Invalid grid square ($2) using default $grid_square"
  else
     grid_square=$2
     do_it_flag=true
  fi
fi

# check for a third command line argument - be silent
if (( $# >= 3 )) ; then
    silent=true
fi


# Convert grid square to upper case
grid_square=$(echo "$grid_square" | tr '[a-z]' '[A-Z]')

#  Test if temporary proximity file already exists
if [ ! -e "$ARDOP_FILE_RAW" ] ; then
    dbgecho "Set do_it flag"
    do_it_flag=true

else # Do this, proximity file exists

    # Determine how old the tmp file is
    dbgecho "Determine how old current file is, stale criteria: $STALE_HOURS hours"

  current_epoch=$(date "+%s")
  file_epoch=$(stat -c %Y $ARDOP_FILE_RAW)
  elapsed_time=$((current_epoch - file_epoch))
  elapsed_hours=$((elapsed_time / 3600))

if ! $silent ; then
    #echo "File: $ARDOP_FILE_RAW is $elapsed_time seconds old"
    echo "Proximity file is: $elapsed_hours hours $((($elapsed_time % 3600)/60)) minute(s), $((elapsed_time % 60)) seconds old"
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
#    generate_post_data
#    echo "early exit"
#    exit 1

# URLS that work
#
#  /gateway/proximity:
#
# {"GridSquare":"String","ServiceCodes":"String","HistoryHours":0,"MaxDistance":0,"OperatingMode":"AnyAll","Key":"String"}
#    Returns a list of gateways corresponding to the request parameters.
#    The list is sorted by distance from the supplied grid square.
#    Check 'OperatingMode' for ardop, file tmp/ardop/ardopprox.txt
#
#
# svc_url="https://api.winlink.org/gateway/proximity?&Key=43137F63FDBA4F3FBEEBA007EB1ED348&Gridsquare=CN88nl&format=json"
# svc_url="https://api.winlink.org/gateway/proximity?&Key=$PL_KEY&Gridsquare=CN88nl&format=json"
#
#  /gateway/listing:
#
# {"ServiceCodes":"String","HistoryHours":0,"ListingType":"Packet","Key":"String"}
#    Returns a formatted gateway listing (to be saved as a text file)
#    Check ?, file tmp/ardop/ardoplist.txt
#          https://api.winlink.org/gateway/listing?&Key=43137F63FDBA4F3FBEEBA007EB1ED348&format=json

#svc_url="https://api.winlink.org/gateway/listing?&Key=$PL_KEY&format=json"
#
#  /gateway/status:
#
# {"HistoryHours":0,"ServiceCodes":"String","Mode":"AnyAll","Key":"String"}
#    Check ?, file tmp/ardop/ardopstatus.txt
# https://api.winlink.org/gateway/status?&Key=43137F63FDBA4F3FBEEBA007EB1ED348&Gridsquare=CN88nl&format=json
svc_url="https://api.winlink.org/gateway/status?&Mode=ardop&Key=$PL_KEY&format=json"

    dbgecho "Using URL: $svc_url"

    curl -s -d "$(generate_post_data)" "$svc_url" > $ARDOP_FILE_RAW
#    curl "$svc_url" > $ARDOP_FILE_RAW
    curlret="$?"
    echo "Created new $ARDOP_FILE_RAW file"

else
    # Display the information in the previously created proximity file
    echo "Using existing proximity file with unknown grid_square"
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

parse_proximity
#parse_status

exit 0
