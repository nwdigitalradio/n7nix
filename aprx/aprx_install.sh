#!/bin/bash
#
#  aprx_install.sh
#
# This script:
#    - downloads lastest source of aprx app. to /usr/local/src
#    - verifys gpsd returns valid sentences
#    - verify version number of installed aprx app
#    - uses here doc to make systemd service file
#    - uses here doc to make aprx configuration file
#
# Written for DRAWS hat running on an RPi but will work with most GPS
#  setups including no GPS
#
# If not running with any GPS device set lat/lon in function
#  set_canned_location()
#
# Requires jq package
#
# Debug flag can be set below or from command line
DEBUG=

# The following variable if set to 'true' will force systemd service
# file creation even if it already exists.
bFORCE_INSTALL=true

# Script prompts for input to set the following variables
CITYNAME=
EMAIL=
USER=
CALLSIGN="N0ONE"

scriptname="`basename $0`"

aprx_ver="2.9.0"
SRC_DIR="/usr/local/src/"
APRX_SRC_DIR="$SRC_DIR/aprx-$aprx_ver"

SERVICE_DIR="/etc/systemd/system"
SERVICE_NAME="aprx.service"

CONFIG_DIR="/etc"
CONFIG_NAME="aprx.conf"
LOG_DIR="/var/log/aprx"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

download_filename="aprx-$aprx_ver.tar.gz"
GPSPIPE="/usr/local/bin/gpspipe"
lat=
lon=

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function set_canned_location

function set_canned_location() {

# Set lat/lon in degrees, decimal minutes
# Lat/Lon ddmm.mm/dddmm.mm format

    lat="4829.07"
    latdir="N"
    lon="12254.11"
    londir="W"

# Set lat/lon data in decimal degrees
# Lat/Lon dd.ddd/(sign)ddd.ddd

    latdd="48.484"
    londd="-122.902"
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

# ===== function get_user

function get_user() {
    # Check if there is only a single user on this system
    if (( `ls /home | wc -l` == 1 )) ; then
        USER=$(ls /home)
    else
        read -t 1 -n 10000 discard
        echo -n "Enter user name ($(echo $USERLIST | tr '\n' ' ')), followed by [enter]:"
        read -ep ": " USER
    fi
}

# ==== function check_user
# verify user name is legit

function check_user() {
   userok=false
   dbgecho "$scriptname: Verify user name: $USER"
   for username in $USERLIST ; do
      if [ "$USER" = "$username" ] ; then
         userok=true;
      fi
   done

   if [ "$userok" = "false" ] ; then
      echo "User name ($USER) does not exist,  must be one of: $USERLIST"
      exit 1
   fi

   dbgecho "using USER: $USER"
}

# ===== function get_user_name
function get_user_name() {

    # Get list of users with home directories
    USERLIST="$(ls /home)"
    USERLIST="$(echo $USERLIST | tr '\n' ' ')"

    # Check if user name was supplied on command line
    if [ -z "$USER" ] ; then
        # prompt for call sign & user name
        # Check if there is only a single user on this system
        get_user
    fi
    # Verify user name
    check_user
}

# ===== function get_ssid

function get_ssid() {

read -t 1 -n 10000 discard
echo -n "Enter ssid (0 - 15) for APRS beacon, followed by [enter]"
read -ep ": " SSID

# Remove any leading zeros
SSID=$((10#$SSID))

if [ -z "${SSID##*[!0-9]*}" ] ; then
   echo "Input: $SSID, not a positive integer"
   return 0
fi

sizessidstr=${#SSID}

if (( sizessidstr > 2 )) || ((sizessidstr < 0 )) ; then
   echo "Invalid ssid: $SSID, length = $sizessidstr, should be 1 or 2 numbers"
   return 0
fi

dbgecho "Using SSID: $SSID"
return 1
}

# ===== function get_callsign

function get_callsign() {

    if [ "$CALLSIGN" == "N0ONE" ] ; then

        read -t 1 -n 10000 discard
        echo -n "Enter call sign, followed by [enter]"
        read -ep ": " CALLSIGN

        sizecallstr=${#CALLSIGN}

        if (( sizecallstr > 6 )) || ((sizecallstr < 3 )) ; then
            echo "Invalid call sign: $CALLSIGN, length = $sizecallstr"
            return 0
        fi

       # Convert callsign to upper case
       CALLSIGN=$(echo "$CALLSIGN" | tr '[a-z]' '[A-Z]')
    fi

    dbgecho "Using CALL SIGN: $CALLSIGN"
    return 1
}

# ===== function get_location

function get_location() {

    read -t 1 -n 10000 discard
    echo -n "Enter location (City name) followed by [enter]"
    read -ep ": " CITYNAME

    dbgecho "Using Location: $CITYNAME"
}

# ===== function get_email

function get_email() {

    read -t 1 -n 10000 discard
    echo -n "Enter email address followed by [enter]"
    read -ep ": " EMAIL

    dbgecho "Using email address: $EMAIL"
}

# ===== function prompt_read

function prompt_read() {
while get_callsign ; do
  echo "Input error, try again"
done

while get_ssid ; do
  echo "Input error, try again"
done
}

# ===== function installed_version_display
function installed_version_display() {
progname="aprx"
    type -P $progname  >/dev/null 2>&1
    if [ "$?"  -ne 0 ]; then
        echo "$progname not installed"
        exit 1
    else
        aprx_ver=$(aprx -V | cut -f2 -d' ')
        echo "Installed aprx version: $aprx_ver"
    fi

}

# ===== function released_version_display
function released_version_display() {

    tarname=$(curl -s https://thelifeofkenneth.com/aprx/release/ | grep -i "aprx-" | tail -n 1 | cut -f2 -d'>' | cut -f1 -d'<')
    if [ $? -ne 0 ] ; then
       echo "Could not parse release directory"
    else
       released_ver=$(echo $tarname | cut -f2 -d'-')
       released_ver=$(basename $released_ver .tar.gz)
       echo "Download file name: $tarname, released version: $released_ver"
    fi
}

# ===== function make_aprx_service_file
function make_aprx_service_file() {
# Make a systemd file

    if [ -f $SERVICE_DIR/$SERVICE_NAME ] && [ ! $bFORCE_INSTALL ] ; then
        echo "Echo service $SERVICE_NAME already exists"
        return
    else
        echo "Creating systemd $SERVICE_NAME file"
    fi

    # Get executable path to aprx program
    aprx_path=$(which aprx)

    sudo tee $SERVICE_DIR/$SERVICE_NAME > /dev/null << EOT
[Unit]
Description=APRX Server, an iGate and Digipeater
After=ax25dev.service
After=sys-subsystem-net-devices-ax0.device

[Service]
User=root
Type=oneshot
RemainAfterExit=yes
ExecStart=$aprx_path

[Install]
WantedBy=multi-user.target
EOT

    sudo systemctl enable $SERVICE_NAME
    sudo systemctl daemon-reload
    sudo systemctl restart $SERVICE_NAME
    if [ ! -z "$DEBUG" ] ; then
        systemctl status $SERVICE_NAME
    fi
}

# ===== function get_aprs_server_passcode

function get_aprs_server_passcode() {
    CALLPASS_DIR="/home/$USER/n7nix/direwolf"
    type -P $CALLPASS_DIR/callpass  &>/dev/null
    if [ $? -ne 0 ] ; then
        echo "Pass code generator does NOT exist"
        return 1
    fi

    pushd $CALLPASS_DIR
    passcode=$(./callpass $CALLSIGN)

    # Get last argument in string
    passcode="${passcode##* }"
    echo "Login code for callsign: $CALLSIGN for APRS tier 2 servers: $passcode"
    popd > /dev/null
    return 0
}

# ===== function make_aprx_config_file

function make_aprx_config_file() {

    if [ -z $lat ] || [ -z $lon ] ; then
        echo "make_aprx_config_file: error lat/lon not set"
        exit 1
    fi
    dbgecho "make_aprx_config_file: Using these co-ordinates: lat: $lat$latdir, lon: $lon$londir"

    # Set up log directory
    if [ ! -d "$LOG_DIR" ] ; then
        dbgecho "Creating log directory $LOG_DIR"
        sudo mkdir $LOG_DIR
    fi

    get_aprs_server_passcode
    # Convert callsign to lower case
    low_callsign=$(echo "$CALLSIGN" | tr '[A-Z]' '[a-z]')

    # NOTE: If you are using "ax25-device" instead of "serial-device" in 'interface' section,
    #  the /etc/ax25/axports file needs to be configured.

    sudo tee $CONFIG_DIR/$CONFIG_NAME > /dev/null << EOT
mycall $CALLSIGN-$SSID

<interface>
  callsign $CALLSIGN-$SSID
  ax25-device \$mycall
  tx-ok true
</interface>

<logging>
  pidfile /var/run/aprx.pid
  rflog $LOG_DIR/aprx-rf.log
  aprxlog $LOG_DIR/aprx.log
</logging>

<aprsis>
  login $CALLSIGN
  passcode $passcode
  server noam.aprs2.net 14580
  filter "r/${latdd}/${londd}/130 t/m"
</aprsis>

<beacon>
  beaconmode both
  cycle-size 10m
  beacon interface ${low_callsign}-$SSID srccall $CALLSIGN-$SSID symbol "I#" lat "$lat$latdir" lon "$lon$londir" \
    comment "$CITYNAME 2m IGate $CALLSIGN-$SSID - $EMAIL - stuff"
</beacon>

<digipeater>
  transmitter \$mycall
  <source>
    source \$mycall
  </source>
  <source>
	source 		APRSIS
	relay-type 	third-party
        filter		"r/${latdd}/${londd}/130 t/m"
	via-path 	WIDE2-2
	msg-path	WIDE1-1
	viscous-delay 	3
  </source>
</digipeater>

<telemetry>
	transmitter	\$mycall
	via		WIDE2-2
	source		\$mycall
</telemetry>
EOT

}

# ===== function set_coordinates

# Get lat/lon co-ordinates in both:
#   - decimal degrees format
#   - degrees with decimal minutes
#
# If gps is not installed or not working co-ordinates are obtained from
# the set_canned_location() routine at top of script

function set_coordinates() {
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

# ===== function usage

function usage() {
   echo "Usage: $scriptname [-d][-l][-c][-d][-g][-h]" >&2
   echo "   -l            Display local version of aprx"
   echo "   -c            Display latest release version of aprx"
   echo "   -d            Set DEBUG flag"
   echo "   -g | --gps    verify gps is working"
   echo "   -h | --help   Display this message"
   echo
}

# ===== main

# Check for any command line arguments
# Command line args are passed with a dash & single letter
#  See usage function

while [[ $# -gt 0 ]] ; do

    key="$1"
    case $key in
        -d)
            DEBUG=1
        ;;
        -l)
            dbgecho "Display local versions only."
            installed_version_display
            exit
        ;;
        -c)
            echo "Check released version number"
            released_version_display
            exit
        ;;
        -u)
            echo "Update aprx after checking version numbers."
            echo
            UPDATE_FLAG=true
        ;;
        -g|--gps)
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
                echo
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
            exit 0
        ;;
        -h|--help)
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

# What it says
get_user_name

# Check for already installed aprx source tree
if [ ! -d "$APRX_SRC_DIR" ] ; then
    cd "$SRC_DIR"
    sudo chown $USER:$USER .

    sudo wget https://thelifeofkenneth.com/aprx/release/$download_filename
    if [ $? -ne 0 ] ; then
        echo "$(tput setaf 1)FAILED to download file: $download_filename $(tput setaf 7)"
    else
        sudo tar xzvf $download_filename
        if [ $? -ne 0 ] ; then
            echo "$(tput setaf 1)FAILED to untar file: $download_filname $(tput setaf 7)"
        else
            sudo chown -R $USER:$USER $APRX_SRC_DIR
            cd $APRX_SRC_DIR
            ./configure
            echo -e "\n$(tput setaf 4)Starting aprx build $(tput setaf 7)\n"
            make
            echo -e "\n$(tput setaf 4)Starting aprx install $(tput setaf 7)\n"
            sudo make install
        fi
    fi
else
    echo "Using previously built aprx-$aprx_ver"
    echo
fi

# Prompt for call sign & SSID
prompt_read

# Prompt for location & email address
get_location
get_email

echo " == Set co-ordinates from GPS"
set_coordinates

echo " == Install aprx config file"
# Needs a valid callsign
make_aprx_config_file

echo " == Install aprx systemd file, restart daemon"
make_aprx_service_file

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: aprx install script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
echo
