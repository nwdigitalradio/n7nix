#!/bin/bash
#
# File : gatewaycnt.sh
# Args:
#  l - build list
#  d - debug mode, do not send e-mail
#

scriptname="`basename $0`"
user=$(whoami)

TMPDIR="$HOME/tmp/rmsgw"
# grid square location for Lopez Island, WA
GRIDSQUARE="cn88nl"
# grid square location for 414 N Prom, Seaside, OR 97138
# GRIDSQUARE="cn85ax"
MAXDIST="30"
# Create a temporary file for cURL output
WINLINK_TMP_FILE="$TMPDIR/rmsgwprox.json"
DEBUG=
BUILDLISTFLAG="false"

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
      -d)
          echo "Turning on debug"
          DEBUG=1
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

WL_KEY="43137F63FDBA4F3FBEEBA007EB1ED348"
curles=0

# Test if temporary directory exists
if [ ! -d "$TMPDIR" ] ; then
   echo "Directory: $TMPDIR does not exist, making ..."
   mkdir -p "$TMPDIR"
else
   dbgecho "Directory: $TMPDIR already exists"
fi

# Test that there is an output file to work on
if [ ! -e "$WINLINK_TMP_FILE" ] || [ "$BUILDLISTFLAG" = "true" ] ; then
   echo "Building file: $WINLINK_TMP_FILE ..."
   # V3 Winlink Web services
#   curl -s http://server.winlink.org:8085"/json/reply/GatewayProximity?GridSquare=$GRIDSQUARE&MaxDistance=$MAXDIST" > $WINLINK_TMP_FILE
   # V5 Winlink Web Services
    svc_url="https://api.winlink.org/gateway/proximity?GridSquare=$GRIDSQUARE&MaxDistance=$MAXDIST&Key=$WL_KEY&format=json"
    dbgecho "Using URL: $svc_url"
    curl -s -d '{"Program":"RMS Gateway", "HistoryHours":48}' -H "Content-Type: application/json" -X POST "$svc_url" > $WINLINK_TMP_FILE  2>&1
    curlres="$?"
fi

if [[ "$curlres" -ne 0 ]] ; then
    echo "Error in cURL return code: $curlres"
    exit 1
fi

js_errorcode=$(cat $WINLINK_TMP_FILE | jq '.ResponseStatus.ErrorCode')

if [ "$js_errorcode" != "null" ] ; then
#    cat $$WINLINK_TMP_FILE | jq '.ResponseStatus | {ErrorCode, Message}'
    js_errormsg=$(cat $WINLINK_TMP_FILE | jq '.ResponseStatus.Message')
    echo
    echo "Debug: Error code: $js_errorcode, Error message: $js_errormsg"
    exit 1
fi

if [ "$SHOWRMSFLAG" = "true" ] ; then
    dbgecho "Showing gateway list in file: $WINLINK_TMP_FILE"
#    cat "$WINLINK_TMP_FILE"

    cat "$WINLINK_TMP_FILE" | jq '.GatewayList[] | {Callsign, Frequency, Baud, Distance}'
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