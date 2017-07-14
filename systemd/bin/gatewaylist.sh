#!/bin/bash
#
# File : gatewaycnt.sh
# Args:
#  l - build list
#  d - debug mode, do not send e-mail
#

scriptname="`basename $0`"
user=$(whoami)

# grid square location for Lopez Island, WA
GRIDSQUARE="cn88nl"
# grid square location for 414 N Prom, Seaside, OR 97138
# GRIDSQUARE="cn85ax"
MAXDIST="30"
# Create a temporary file for cURL output
WINLINK_TMP_FILE="/tmp/rmsgwprox.json"


# ===== function usage
function usage() {
   echo "Usage: $scriptname [-c][-l][-m <max_distance_in_miles>[-g <grid_square>][-s][-h]" >&2
   echo "   -c | --count  count number of RMS Stations"
   echo "   -l | --list  build list of RMS Stations"
   echo "   -m | --max  arg max distance in miles"
   echo "   -g | --gridsquare arg grid square location"
   echo "   -s | --show  show all Stations"
   echo "   -d | --debug  set debug flag"
   echo "   -h | --help  display this message"
   echo
}
# ===== function debugecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== main
# Is curl installed?

type -P curl &>/dev/null
if [ $? -ne 0 ] ; then
  echo "$scriptname: Install cURL please"
  exit 1
fi
# if there are no args default to show RMS Gateways & Count of gateways
if [[ $# -eq 0 ]] ; then
   SHOWRMSFLAG="true"
   COUNTRMSFLAG="true"
fi

# if there are any args then parse them
while [[ $# -gt 0 ]] ; do
   key="$1"

   case $key in
      -l|--list)
         echo "Build list of Linux RMS Gateways"
	 BUILDLISTFLAG="true"
	 ;;
      -s|--show)
	 SHOWRMSFLAG="true"
	 ;;
      -c|--count)
	 COUNTRMSFLAG="true"
	 ;;
      -m|--maxdist)
	 BUILDLISTFLAG="true"
         MAXDIST=$2
	 shift # past argument
	 echo "Got maxdist arg of $MAXDIST"
         ;;
      -g|--gridsquare)
	 BUILDLISTFLAG="true"
         GRIDSQUARE=$2
	 shift # past argument
	 echo "Got GRIDSQUARE arg of $GRIDSQUARE"
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


# Test that there is an output file to work on
if [ ! -e "$WINLINK_TMP_FILE" ] || [ "$BUILDLISTFLAG" = "true" ] ; then
   echo "Building file: $WINLINK_TMP_FILE ..."
   curl -s http://server.winlink.org:8085"/json/reply/GatewayProximity?GridSquare=$GRIDSQUARE&MaxDistance=$MAXDIST" > $WINLINK_TMP_FILE
fi

if [ "$SHOWRMSFLAG" = "true" ] ; then
    cat $WINLINK_TMP_FILE | jq '.GatewayList[] | {Callsign, Frequency, Baud, Distance}'
fi
if [ "$COUNTRMSFLAG" = "true" ] ; then
    RMSCNT=$(cat $WINLINK_TMP_FILE | jq '.GatewayList[] | {Callsign, Frequency, Baud, Distance}' | grep -i callsign | wc -l)

    if [ "$BUILDLISTFLAG" = "true" ] ; then
       echo "Found $RMSCNT stations $MAXDIST miles from grid square $GRIDSQUARE"
    else
       echo "Found $RMSCNT stations"
    fi
fi

exit 0