#!/bin/bash
#
# Output a wav file to a sound card
# Used to output DTMF tones to set baud rate on a remote system
#
# Usage:
#   send-ttcmd.sh [-c _connector_location_]
#
# Uses dtmf-generator python program to make wav file
# python3.7 dtmf-generator.py -p BA236288*A6B76B4C9B7# -f 20000 -t 0.08 -s 0.08 -o dtmfcmd.wav -a 90 -d
#

scriptname="`basename $0`"
USER=
DEBUG=
# Force generation of wav file even if it already exists.
FORCE_GEN=
CALLSIGN="N0ONE"
AX25_CFGDIR="/usr/local/etc/ax25"
AXPORTS_FILE="$AX25_CFGDIR/axports"

# use left connector on a draws hat
udrc_prod_id=4
connector="left"

PROD_ID_NAMES=("INVALID" "INVALID" "UDRC" "UDRC II" "DRAWS" "1WSpot")
NWDIG_VENDOR_NAME="NW Digital Radio"

wavefile="dtmfcmd.wav"
#default to left channel on a DRAWS hat
# gpio_pin can be either 12 or 23
gpio_pin=12

CMDSTR="BA236288*A6B76B4C9B7#"
declare -A dmtffreq=( \
[1 1]=697 [1 2]=1209 [2 1]=697 [2 2]=1336 [3 1]=697 [3 2]=1477 [A 1]=697 [A 2]=1633 \
[4 1]=770 [4 2]=1209 [5 1]=770 [5 2]=1336 [6 1]=770 [6 2]=1477 [B 1]=770 [B 2]=1633 \
[7 1]=852 [7 2]=1209 [8 1]=852 [8 2]=1336 [9 1]=852 [9 2]=1477 [C 1]=852 [C 2]=1633 \
[* 1]=941 [* 2]=1209 [0 1]=941 [0 2]=1336 [# 1]=941 [# 2]=1477 [D 1]=941 [D 2]=1633 )

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

# ===== function usage
function usage() {
   echo "Usage: $scriptname [-c <connector>][-h]" >&2
   echo "   -c connector location, either left (mDin6) or right (hd15/mDin6), default: right"
   echo "   -d set debug flag"
   echo "   -h no arg, display this message"
   echo
}
# ===== function debugecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function ctrl_c
# Shut off both PTT gpio's

function ctrl_c() {
        echo "** carrier off from trapped CTRL-C"
	gpio -g write 12 0
	gpio -g write 23 0
	exit
}

# ===== function get_user

function get_user() {
   # Check if there is only a single user on this system
   if (( `ls /home | wc -l` == 1 )) ; then
      USER=$(ls /home)
   else
      echo "Enter user name ($(echo $USERLIST | tr '\n' ' ')), followed by [enter]:"
      read -e USER
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

    # Verify user name
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

# ===== function validate_callsign
# Validate callsign

function validate_callsign() {

    callsign="$1"
    sizecallstr=${#callsign}

    if (( sizecallstr > 6 )) || ((sizecallstr < 3 )) ; then
        echo "Invalid call sign: $callsign, length = $sizecallstr"
        return 1
    fi

    # Convert callsign to upper case
    CALLSIGN=$(echo "$callsign" | tr '[a-z]' '[A-Z]')
    return 0
}

# ===== function get_callsign

function get_callsign() {
    retcode=0
    # Check if call sign var has already been set
    if [ "$CALLSIGN" == "N0ONE" ] ; then
        echo "Enter call sign, followed by [enter]:"
        read -e callsign
    else
        echo "Error: call sign: $CALLSIGN"
    fi
    validate_callsign $callsign
    if [ $? -eq 0 ] ; then
        dbgecho "Using CALL SIGN: $CALLSIGN"
        retcode=1
    else
        echo "Bad callsign found: $callsign"
    fi
    return $retcode
}

function get_axports_callsign() {
    retcode=1
    # get the first port line after the last comment
    #axports_line=$(tail -n3 $AXPORTS_FILE | grep -v "#" | grep -v "N0ONE" |  head -n 1)
    axports_line=$(tail -n3 $AXPORTS_FILE | grep -vE "^#|N0ONE" |  head -n 1)

    echo "Using axports line: $axports_line"
    port=$(echo $axports_line | cut -d' ' -f1)
    # get rid of SSID
    callsign=$(echo $axports_line | tr -s '[[:space:]]' | cut -d' ' -f2 | cut -d '-' -f1)
    if [ ! -z $callsign ] ; then
        validate_callsign $callsign
        if [ $? -eq 0 ] ; then
            dbgecho "Using CALL SIGN: $CALLSIGN"
            retcode=0
        else
            echo "Bad callsign found: $callsign"
            CALLSIGN="N0ONE"
        fi
    fi
    return $retcode
}

# function id_check
# Verify the required sound card exists

function id_check() {

    retcode=0 # error ret code
    # Verify that aplay enumerates udrc sound card

    CARDNO=$(aplay -l | grep -i udrc)

    if [ ! -z "$CARDNO" ] ; then
        echo "udrc card number line: $CARDNO"
        CARDNO=$(echo $CARDNO | cut -d ' ' -f2 | cut -d':' -f1)
        echo "udrc is sound card #$CARDNO"
        retcode=2
    else
        echo "No udrc sound card found."
    fi
    return $retcode
}

function use_sox() {
# Verify required programs are installed
for prog_name in `echo ${PROGLIST}` ; do
   type -P $prog_name &> /dev/null
   if [ $? -ne 0 ] ; then
      echo "$scriptname: Need to Install $prog_name program"
      NEEDPKG_FLAG=true
   fi
done
if [ "$NEEDPKG_FLAG" = "true" ] ; then
   echo "Installing required packages"
   dbgecho "Debian packages: for aplay install alsa-utils, for gpio, install wiringpi"
   sudo apt-get -y -q install alsa-utils
   if [ ! -e "/usr/local/src/wiringpi-latest.deb" ] ; then
       # Need wiringPi version 2.52 for Raspberry Pi 4 which is not yet in Debian repos.
       wget -P /usr/local/src https://project-downloads.drogon.net/wiringpi-latest.deb
   fi
   sudo dpkg -i /usr/local/src/wiringpi-latest.deb
fi
}

# ===== function device_name_verify
# Verify that sound card device exists

function device_name_verify() {
retcode=0
return $retcode
}

# ===== main

PROGLIST="gpio sox"
NEEDPKG_FLAG=false

# Check if running as root
if [[ $EUID != 0 ]] ; then
   USER=$(whoami)
   dbgecho "Running as user: $USER"
else
    # Running as root, get a user name
    get_user_name
    echo
    echo "Not required to be root to run this script."
    echo
    exit 1
fi

bin="/home/$USER/bin"

dbgecho "Parse command line args"
# Command line args are passed with a dash & single letter
#  See usage function

while [[ $# -gt 0 ]] ; do
key="$1"

case $key in
   -c|--connector)
      connector="$2"
      shift # past argument
   ;;
   -f|--force)
       FORCE_GEN=1
   ;;
   -d|--debug)
      DEBUG=1
      echo "Debug mode on"
   ;;
   -h|--help|?)
      usage
      exit 0
   ;;
   *)
      # unknown option
      echo "Unknow option: $key"
      usage
      exit 1
   ;;
esac
shift # past argument or value
done

## Get a valid callsign

get_axports_callsign
retcode="$?"
echo "retcode: $retcode from get_axports_callsign"

if [ $retcode -ne 0 ] ; then

    ## Get a callsign from command line
    echo "prompt for a callsign:"
    while get_callsign ; do
        retcode=$?
        echo "Input error ($retcode), try again"
    done
fi

## Have a call sign convert it into TouchTone string
text2tt N7NIX
call_ttones=$((grep -A 1 "two-key method.*" <<< $(text2tt N7NIX)) | tail -n1)
echo "tt1: $call_ttones"
tt_str1=$(echo $call_ttones | cut -f2 -d'"')
tt_str2=$(echo $call_ttones | cut -f2 -d'=')
# squish all the spaces
tt_str2=$(echo $tt_str2 |tr -s '[[:space:]]')
ttcallsign="A$tt_str1$tt_str2"

dbgecho "Verify required programs"
use_sox

# Verify a UDRC HAT is installed
id_check
id_check_ret=$?
if [ $id_check_ret -eq 0 ] || [ $id_check_ret -eq 1 ] ; then
   echo "No UDRC or DRAWS found, id_check=$id_check_ret exiting ..."
   exit 1
fi

# Validate channel location
# Set correct PTT gpio for channel 0 or 1
# DRAWS Hat has channel 0 on left & channel 1 on right connector
case $connector in
   left)
      # Check for UDRC II
      if [ $udrc_prod_id == 3 ]  ; then
         # uses audio channel 1 PTT gpio
         gpio_pin=23
      else
         # Original UDRC & DRAWS HAT use chan 0 PTT gpio
         gpio_pin=12
      fi
   ;;
   right)
      if [ $udrc_prod_id == 4 ] ; then
          # use channel 1 PTT gpio
          gpio_pin=23
      else
          # Original UDRC & UDRC II use chan 0 PTT gpio
          gpio_pin=12
      fi
   ;;
   *)
      echo "Wrong connector location specified: $connector"
      usage
      exit 1
   ;;
esac

# Need path to ax25-stop script
# - $USER variable should be set
# aplay will NOT work if direwolf or any other sound card program is running
pid=$(pidof direwolf)
if [ $? -eq 0 ] ; then
   echo "Direwolf is running, with a pid of $pid"
   echo "Stopping this process"
   sudo $bin/ax25-stop
fi

# Won't work unless gpio 4 is set to ALT 0
# gpio 4 (BCM) is calld gpio. 7 by WiringPi
mode_gpio7="$(gpio readall | grep -i "gpio. 7" | cut -d "|" -f 5 | tr -d '[:space:]')"
if [ "$mode_gpio7" != "ALT0" ] ; then
   echo
   echo "  gpio 7 is in wrong mode: |$mode_gpio7|, should be: ALT0"
   echo "  Setting gpio set to mode ALT0"
   gpio mode 7 ALT0
   echo
fi

echo "Test with PTT GPIO $gpio_pin"

# Enable PTT
gpio -g mode $gpio_pin out
gpio -g write $gpio_pin 1

# This does not work
#aplay -vv -D hw:CARD=udrc,DEV=0 $wavefile
# this works
### aplay -vv -f s16_LE -D plughw:CARD=udrc,DEV=0 $wavefile

#aplay -vv -D "plughw:1,0" $wavefile
#aplay -vv -f s32_LE -c 2 -d 20 -D plughw:2,0 $wavefile

export AUDIODEV=plughw:CARD=udrc,DEV=0
echo "Using audio device $AUDIODEV with play"

#play $wavefile
CMDSTR="BA23"
CMDSTR="BA236288*${ttcallsign}#"
echo "Sending command string: $CMDSTR"
for (( i=0; i < ${#CMDSTR}; i++)) ; do
  tonechar="${CMDSTR:$i:1}"
  if [ -z ${dmtffreq[$tonechar 1]} ] || [ -z ${dmtffreq[$tonechar 2]} ] ; then
      echo "Frequencies for DTMF char $tonechar is not defined"
  fi
  dbgecho "$tonechar First: ${dmtffreq[$tonechar 1]} Second: ${dmtffreq[$tonechar 2]}"
  play -q -n synth 0.1 sin ${dmtffreq[$tonechar 1]} sin ${dmtffreq[$tonechar 2]} remix 1,2 2> /dev/null
  # dbgecho "Return code from aplay: $?"
done

# Turn off PTT
gpio -g write $gpio_pin 0

echo "Is carrier turned off gpio 12: $(gpio -g read 12), gpio 23: $(gpio -g read 23)?"

exit 0
