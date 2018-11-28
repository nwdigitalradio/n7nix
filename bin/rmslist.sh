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

myname="`basename $0`"

#TMPDIR="/tmp"
TMPDIR="$HOME/tmp"
RMS_PROXIMITY_FILE_RAW="$TMPDIR/rmsgwprox.json"
RMS_PROXIMITY_FILE_OUT="$TMPDIR/rmsgwprox.txt"
PKG_REQUIRE="jq curl"

do_it_flag=0
DEBUG=

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
  if (( $1 > 0 )) 2>/dev/null; then
    max_distance=$1
    do_it_flag=1

  else
    echo "$0: arg ($1) invalid distance"
    usage
  fi
fi


# check for a second command line argument - grid square

if (( $# == 2 )) ; then
  if [[ "$2" =~ [^a-zA-Z0-9] ]]; then
     echo "Invalid grid square ($2) using default $grid_square"
  else
     grid_square=$2
     do_it_flag=1
  fi
fi

# Convert grid square to upper case
grid_square=$(echo "$grid_square" | tr '[a-z]' '[A-Z]')

#  Test if temporary proximity file already exists
if [ ! -e "$RMS_PROXIMITY_FILE_RAW" ] ; then
  do_it_flag=1

else # Do this, proximity file exists

  # Determine how old the tmp file is

  current_epoch=$(date "+%s")
  file_epoch=$(stat -c %Y $RMS_PROXIMITY_FILE_RAW)
  elapsed_time=$((current_epoch - file_epoch))
  elapsed_hours=$((elapsed_time / 3600))

#echo "File: $RMS_PROXIMITY_FILE_RAW is $elapsed_time seconds old"
  echo "Proximity file is: $elapsed_hours hours $((($elapsed_time % 3600)/60)) minute(s), $((elapsed_time % 60)) seconds old"

# Only refresh the proximity file every day or so
  if ((elapsed_hours > 10)) ; then
    do_it_flag=1
  fi
fi # END Test if temporary proximity file already exists

WL_KEY="43137F63FDBA4F3FBEEBA007EB1ED348"
curlret=0
# temporary - disable Winlink web services interrogation for testing $RMS_PROXIMITY_FILE_PARSE
#do_it_flag=1

if [ $do_it_flag -ne 0 ]; then
    # Get the proximity information from the winlink server
    echo "Using distance of $max_distance miles & grid square $grid_square"
    echo
#    generate_post_data
#    echo "early exit"
#    exit 1

    # V3 Winlink Web Services
#   curl -s http://server.winlink.org:8085"/json/reply/GatewayProximity?GridSquare=$grid_square&MaxDistance=$max_distance" > $RMS_PROXIMITY_FILE_RAW
    # V5 Winlink Web Services
#    svc_url="https://api.winlink.org/gateway/proximity?GridSquare=$grid_square&MaxDistance=$max_distance&Key=$WL_KEY&format=json"
    svc_url="https://api.winlink.org/gateway/proximity?GridSquare=$grid_square&MaxDistance=$max_distance&Key=$WL_KEY&format=json"

    dbgecho "Using URL: $svc_url"

    curl -s -d "$(generate_post_data)" "$svc_url" > $RMS_PROXIMITY_FILE_RAW
    curlret="$?"
else
    # Display the information in the previously created proximity file
    echo "Using existing proximity file with unknown grid_square"
    echo
fi

if [ "$curlret" -ne 0 ] ; then
    dbgecho "cURL return code: $curlret"
    if [ ! -z $DEBUG ] ; then
        echo "Dump raw proxmity json file"
        cat $RMS_PROXIMITY_FILE_RAW
    fi
#    echo
#    cat $RMS_PROXIMITY_FILE_RAW | jq '.ResponseStatus | {ErrorCode, Message}'
    js_errorcode=$(cat $RMS_PROXIMITY_FILE_RAW | jq '.ResponseStatus.ErrorCode')
    js_errormsg=$(cat $RMS_PROXIMITY_FILE_RAW | jq '.ResponseStatus.Message')
    echo
    echo "Debug: Error code: $js_errorcode, Error message: $js_errormsg"
    exit 1
fi

js_errorcode=$(cat $RMS_PROXIMITY_FILE_RAW | jq '.ResponseStatus.ErrorCode')

if [ "$js_errorcode" != "null" ] ; then
#    cat $RMS_PROXIMITY_FILE_RAW | jq '.ResponseStatus | {ErrorCode, Message}'
    js_errormsg=$(cat $RMS_PROXIMITY_FILE_RAW | jq '.ResponseStatus.Message')
    echo
    echo "Debug: Error code: $js_errorcode, Error message: $js_errormsg"
    exit 1
fi

dbgecho "Have good request json"

# Parse the JSON file
# cat $RMS_PROXIMITY_FILE_RAW | jq '.GatewayList[] | {Callsign, Frequency, Distance}' > $RMS_PROXIMITY_FILE_PARSE


# Print the table header
echo "  Callsign       Frequency  Distance    Baud"

# iterate through the JSON parsed file
for k in $(jq '.GatewayList | keys | .[]' $RMS_PROXIMITY_FILE_RAW); do
    value=$(jq -r ".GatewayList[$k]" $RMS_PROXIMITY_FILE_RAW);

    callsign=$(jq -r '.Callsign' <<< $value);
    callsign=$(echo "$callsign" | tr -d ' ')
    frequency=$(jq -r '.Frequency' <<< $value);
    baud=$(jq -r '.Baud' <<< $value);
    distance=$(jq -r '.Distance' <<< $value);

    printf ' %-10s\t%10s\t%s\t%4s\n' "$callsign" "$frequency" "$distance" "$baud"
done 2>&1 | tee $RMS_PROXIMITY_FILE_OUT

exit 0
