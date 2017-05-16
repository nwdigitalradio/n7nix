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

TMPDIR="/tmp"
RMS_PROXIMITY_FILE_RAW="$TMPDIR/rmsgwprox.json"
RMS_PROXIMITY_FILE_PARSE="$TMPDIR/rmsgwprox.txt"
PKG_REQUIRE="jq curl"

do_it_flag=0

max_distance=30        # default max distance of RMS Gateways
grid_square="cn88nl"   # default grid square location or origin

# Define a single white space for column formating
singlewhitespace=" "


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
# Pad string with spaces
#
# arg1 = string
# arg2 = length to pad
#
format_space () {
   local whitespace=" "
   strarg="$1"
   lenarg="$2"
   strlen=${#strarg}
   whitelen=$(( lenarg-strlen ))
   for (( i=0; i<whitelen; i++ )) ; do
       whitespace+="$singlewhitespace"
    done;
# return string of whitespace(s)
    echo -n "$whitespace"
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
  if ((elapsed_hours > 23)) ; then
    do_it_flag=1
  fi
fi # END Test if temporary proximity file already exists

# temporary - disable Winlink web services interrogation for testing
# do_it_flag=0

if [ $do_it_flag -ne 0 ]; then
  # Get the proximity information from the winlink server
  echo "Using distance of $max_distance miles & grid square $grid_square"
  echo
  curl -s http://server.winlink.org:8085"/json/reply/GatewayProximity?GridSquare=$grid_square&MaxDistance=$max_distance" > $RMS_PROXIMITY_FILE_RAW
else
  # Display the information in the previously created proximity file
  echo "Using existing proximity file with unknown grid_square"
  echo
fi

# Parse the JSON file
cat $RMS_PROXIMITY_FILE_RAW | jq '.GatewayList[] | {Callsign, Frequency, Distance}' > $RMS_PROXIMITY_FILE_PARSE

# Print the table header
echo "  Callsign        Frequency  Distance"

# iterate through the JSON parsed file
while read line ; do

  xcallsign=$(echo $line | grep -i "callsign")
  # If callsign variable exists, echo line to console
  if [ -n "$xcallsign" ] ; then
    callsign=$(echo $xcallsign | cut -d ':' -f2)

#    format_space $callsign 15

    # remove any spaces
    frequency=$(echo "$frequency" | tr -d ' ')
    callsign=$(echo "$callsign" | tr -d ' ')
    # remove trailing comma
    callsign="${callsign%,}"
#    callsign=$(echo -n "${callsign//[[:space:]]/}")

    # remove both double quotes
    callsign="${callsign#\"}"
    callsign="${callsign%\"}"

    continue
  fi

  xfrequency=$(echo $line | grep -i "frequency")
  if [ -n "$xfrequency" ] ; then
    frequency=$(echo $xfrequency | cut -d ':' -f2)
    # get rid of trailing comma
    frequency="${frequency%,}"
#    echo "Freq: $frequency"
    continue
  fi

  xdistance=$(echo $line | grep -i "distance")
  if [ -n "$xdistance" ] ; then
    distance=$(echo $xdistance | cut -d ':' -f2)
    # get rid of trailing comma
    distance="${distance%,}"
#    echo "Dist: $distance"

    echo  "  $callsign$(format_space $callsign 13) $frequency $(format_space $frequency 9) $distance"

  fi

done < $RMS_PROXIMITY_FILE_PARSE

exit 0
