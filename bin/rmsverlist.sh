#!/bin/bash
#
# rmsverlist.sh
#
# Interrogate Winlink web services
# requires curl & jq
#
# jq JSON parser is in these Debian distros:
#    wheezy-backports, jessie & stretch
# If you need to download it get it from here:
# http://stedolan.github.io/jq/download/
#

scriptname="`basename $0`"

TMPDIR="$HOME/tmp/rmsgw"
RMS_VERSION_FILE_RAW="$TMPDIR/rmsgwver.json"
RMS_VERSION_FILE_OUT="$TMPDIR/rmsgwver.txt"
PKG_REQUIRE="jq curl"

# Intialize default version file refresh interval in hours
REFRESH_INTERVAL=10
# Convert refresh interval in hours to seconds
let REFRESH_INTERVAL=REFRESH_INTERVAL*60*60

# controls when to call winlink web service api
do_it_flag=0
DEBUG=

## ============ functions ============

function dbgecho  { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }
#
# Display program help info
#
usage () {
	(
	echo "Usage: $scriptname [-c][-d][-h][-t][-T]"
        echo "    -c switch to turn on displaying call sign list"
        echo "    -d switch to turn on verbose debug display"
        echo "    -D switch to turn on printing date"
        echo "    -t <int> Set refresh interval in seconds. default: $REFRESH_INTERVAL seconds"
        echo "    -T switch to turn off making Winlink service call."
        echo "    -h display this message."
        echo

	echo " exiting ..."
	) 1>&2
	exit 1
}

# is_pkg_installed

function is_pkg_installed() {
   return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed")
}

# print elapsed time in hours, minutes & seconds
# arg1 elapsed time in seconds

function print_elapsed_time() {
    et=$1
    echo "$((et / 3600)) hours, $(((et % 3600)/60)) minute(s), $((et % 60)) seconds old"
}

# Verify that access time has not been violated
# arg 1: file name
# arg 2: max request interval in seconds

function check_file_age() {
    retval=1
    dbgecho "Args file: $1, Check interval: $2"

    # Does the file even exist?
    if [ ! -e "$1" ] ; then
        touch "$1"
        return 0
    fi
    # Determine how old the reference file is
    current_epoch=$(date "+%s")
    file_epoch=$(stat -c %Y $1)
    elapsed_time=$((current_epoch - file_epoch))

    dbgecho "Reference file is: $(print_elapsed_time $elapsed_time)"

    # Only refresh the version file every day or so
    if (( elapsed_time >= $2 )) ; then
        dbgecho "Refresh time expired for file $1 elapsed: $(print_elapsed_time $elapsed_time)"
        retval=0
    else
        dbgecho "Refresh time NOT expired for file $1 elapsed: $(print_elapsed_time $elapsed_time)"
        retval=1
    fi
    return $retval
}

#
## =============== main ===============
#
# Initial TEST ONLY switch
TEST_ONLY="false"
COUNT_ONLY="true"
DATE_ON="false"

# Check for any command line arguments
# Command line args are passed with a dash & single letter
#  See usage function

while [[ $# -gt 0 ]] ; do

    key="$1"
    case $key in
        -c)
            dbgecho "Turn on displaying call sign list"
            COUNT_ONLY="false"
        ;;

        -d)
            echo "Turning on debug"
            DEBUG=1
        ;;
        -D)
            echo "Turning on printing date"
            DATE_ON="true"
        ;;
        -t)
            REFRESH_INTERVAL="$2"
            shift  #past value
            # Verify argument is an integer
            re='^[0-9]+$'
            if ! [[ $REFRESH_INTERVAL =~ $re ]] ; then
                echo "Error setting refresh interval: $REFRESH_INTERVAL not an integer"
                exit 1
            fi
            dbgecho "Set time in hours of last Winlink Service call to $REFRESH_INTERVAL seconds."
        ;;
        -T)
            dbgecho "Turn off making Winlink Service call regardless of refresh_interval"
            TEST_ONLY="true"
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

# check if required packages are installed
dbgecho "Check packages: $PKG_REQUIRE"
needs_pkg=false

for pkg_name in `echo ${PKG_REQUIRE}` ; do

   is_pkg_installed $pkg_name
   if [ $? -eq 0 ] ; then
      echo "$scriptname: Will Install $pkg_name program"
      needs_pkg=true
      break
   fi
done

# Check for running as root
if [[ $EUID == 0 ]] ; then
   echo "Do not need to be root to run this program."
fi

if [ "$needs_pkg" = "true" ] ; then

   sudo apt-get install -y -q $PKG_REQUIRE
   if [ "$?" -ne 0 ] ; then
      echo "Required package install failed. Please try this command manually:"
      echo "apt-get install -y $PKG_REQUIRE"
      exit 1
   fi
fi

# Test if temporary directory exists
if [ ! -d "$TMPDIR" ] ; then
   echo "Directory: $TMPDIR does not exist, making ..."
   mkdir -p "$TMPDIR"
else
   dbgecho "Directory: $TMPDIR already exists"
fi

#  Test if temporary version file already exists and is not empty
if [ -s "$RMS_VERSION_FILE_RAW" ] ; then
    # Version file exists & is not empty

    # Determine how old the tmp file is
    # Only refresh the version file every day or so
    check_file_age $RMS_VERSION_FILE_RAW $REFRESH_INTERVAL
    if [ "$?" -eq 0 ] ; then
        echo "Refreshing version file"
        do_it_flag=1
    else
      dbgecho "Will NOT refresh version file"
    fi
else # Do this, if version file does NOT exist
    dbgecho "File $RMS_VERSION_FILE_RAW does not exist, running winlink api"
    do_it_flag=1
    elapsed_time=0

fi # END Test if temporary version file already exists and not empty

WL_KEY="CD2E1C9C7CD4417FAEF4C7F2A70156A3"
WL_PROGNAME="RMS Gateway"
curlres=0
# temporary - disable Winlink web services interrogation for testing $RMS_VERSION_FILE_PARSE
# do_it_flag=0

# Check if refresh interval has passed
if [ "$do_it_flag" -ne 0 ]; then
    # Get the version information from the winlink server
    echo
    # V5 Winlink Web Services
#    svc_url="https://api.winlink.org/version/list?Program=$WL_PROGNAME&HistoryHours=48&Key=$WL_KEY&format=json"
#    svc_url="https://api.winlink.org/version/list?&Program=$WL_PROGNAME&Key=$WL_KEY&format=json"
    svc_url="https://api.winlink.org/version/list?&Key=$WL_KEY&format=json"
    echo "Using URL: $svc_url"

#    curl -s "$svc_url" > $RMS_VERSION_FILE_RAW  2>&1
    curl -s -d '{"Program":"RMS Gateway", "HistoryHours":48}' -H "Content-Type: application/json" -X POST "$svc_url" > $RMS_VERSION_FILE_RAW  2>&1
    curlres="$?"
else
    # Display the information in the previously created version file
    echo "Using existing version file, refresh interval: $(print_elapsed_time $REFRESH_INTERVAL)"
    echo
fi

if [ "$curlres" -ne "0" ] ; then
    echo "Error in Curl return code: $curlres"
    exit 1
fi

#if [ ! -z "$DEBUG" ] && [ -s "$RMS_VERSION_FILE_RAW" ] ; then
#    echo "Dump raw version json file"
#    cat $RMS_VERSION_FILE_RAW
#fi

if [ ! -s "$RMS_VERSION_FILE_RAW" ] ; then
    echo "Raw version file: $RMS_VERSION_FILE_RAW, does not exist"
    exit 1
fi

js_errorcode=$(cat $RMS_VERSION_FILE_RAW | jq '.ResponseStatus.ErrorCode')

if [ "$js_errorcode" != "null" ] ; then
    dbgecho "Found ErrorCode: $js_errorcode"
#    cat $RMS_VERSION_FILE_RAW | jq '.ResponseStatus | {ErrorCode, Message}'
    js_errormsg=$(cat $RMS_VERSION_FILE_RAW | jq '.ResponseStatus.Message')
    echo
    echo "Debug: Error code: $js_errorcode, Error message: $js_errormsg"
    exit 1
fi

dbgecho "Have good request json"

# Parse the JSON file
# cat $RMS_VERSION_FILE_RAW | jq '.VersionList[] | {Callsign, Program, Version}' > $RMS_VERSION_FILE_PARSE

# iterate through the JSON file
for k in $(jq '.VersionList | keys | .[]' $RMS_VERSION_FILE_RAW); do
value=$(jq -r ".VersionList[$k]" $RMS_VERSION_FILE_RAW);
  program=$(jq -r '.Program' <<< $value);
  if [ "$program" = "RMS Gateway" ] ; then
    callsign=$(jq -r '.Callsign' <<< $value);
    callsign=$(echo "$callsign" | tr -d ' ')
    version=$(jq -r '.Version' <<< $value);

    timestamp=$(jq -r '.Timestamp' <<< $value);

    # remove both forward slashes
    timestamp="${timestamp#/Date(}"
    timestamp="${timestamp%)/}"

    # git rid of last 3 digits (milliseconds)
    convert_time=${timestamp:0:10}
    timestr="$(date -d @$convert_time)"

    if [ "$DATE_ON" = "true" ] ; then
        printf ' %-9s\t%s\t%s\n' "$callsign" "$version" "$timestr"
    else
        printf ' %-9s\t%s\n' "$callsign" "$version"
    fi
 fi
done > $RMS_VERSION_FILE_OUT

if [ "$COUNT_ONLY" = "false" ] ; then
    # Print the table header
    if [ "$DATE_ON" = "true" ] ; then
        echo "  Callsign     Version       Timestamp"
    else
        echo "  Callsign     Version"
    fi
    sort -k 2 --numeric-sort $RMS_VERSION_FILE_OUT
    #sort -k 3 --numeric-sort $RMS_VERSION_FILE_OUT
    echo
fi

echo "Below rev: $(grep -c "2\.4\." $RMS_VERSION_FILE_OUT), Current: $(grep -c "2\.5\." $RMS_VERSION_FILE_OUT), Total: $(wc -l $RMS_VERSION_FILE_OUT | cut -d ' ' -f1) at $(date "+%b %_d %T %Z %Y")"
echo "RMS GW Version file is: $( print_elapsed_time $elapsed_time)"
