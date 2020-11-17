#!/bin/bash
#
# Usage:
#   measure_deviate.sh [-f _tone_frequency_][-c _connector_location_][-l _tone_duration_][-h]
#
# Examples:
# On a UDRC II, send 2200 Hz sine wave out mini din-6 connector
#   for 30 seconds
# ./measure_deviate.sh -f 2200 -c left -l 30
#
# On a UDRC II, send 1200 Hz sine wave out HD-15 connector
#   for 30 seconds
# ./measure_deviate.sh -f 1200 -c right
#

scriptname="`basename $0`"
USER=
DEBUG=
NWDR=false

firmware_prodfile="/sys/firmware/devicetree/base/hat/product"
firmware_prod_idfile="/sys/firmware/devicetree/base/hat/product_id"
firmware_vendorfile="/sys/firmware/devicetree/base/hat/vendor"

PROD_ID_NAMES=("INVALID" "INVALID" "UDRC" "UDRC II" "DRAWS" "1WSpot")
NWDIG_VENDOR_NAME="NW Digital Radio"

# Default to using this tone in HZ
freq=2200
tone_length=30
default_tone_length=30
connector="left"
wavefile_basename="hzsin.wav"
wavefile="$freq$wavefile_basename"
#default to UDRC II, channel 0
gpio_pin=12

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT
# ===== function usage
function usage() {
   echo "Usage: $scriptname [-f <tone_frequency][-c <connector>][-l <tone_duration>][-h]" >&2
   echo "   -f tone frequency in Hz (10 - 20000), default: 2200"
   echo "   -c connector location, either left (mDin6) or right (hd15/mDin6), default: right"
   echo "   -l length of tone in seconds, default 30"
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
    if [ $NWDR = "true" ] ; then
        nwdr_ptt_off 12
        nwdr_ptt_off 23
    else
        usb_ptt_off 3
    fi
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

# ===== function EEPROM id_check

# Return code:
# 0 = no EEPROM or no device tree found
# 1 = HAT found but not a UDRC
# 2 = UDRC
# 3 = UDRC II
# 4 = DRAWS
# 5 = 1WSpot

function id_check() {
# Initialize to EEPROM not found
udrc_prod_id=0

# Does firmware file exist
if [ -f $firmware_prodfile ] ; then
   # Read product file
   UDRC_PROD="$(tr -d '\0' <$firmware_prodfile)"
   # Read product file
   FIRM_VENDOR="$(tr -d '\0' <$firmware_vendorfile)"
   # Read product id file
   UDRC_ID="$(tr -d '\0' <$firmware_prod_idfile)"
   #get last character in product id file
   UDRC_ID=${UDRC_ID: -1}

   dbgecho "UDRC_PROD: $UDRC_PROD, ID: $UDRC_ID"

   if [[ "$FIRM_VENDOR" == "$NWDIG_VENDOR_NAME" ]] ; then
      case $UDRC_PROD in
         "Universal Digital Radio Controller")
            udrc_prod_id=2
         ;;
         "Universal Digital Radio Controller II")
            udrc_prod_id=3
         ;;
         "Digital Radio Amateur Work Station")
            udrc_prod_id=4
         ;;
         "1WSpot")
            udrc_prod_id=5
         ;;
         *)
            echo "Found something but not a UDRC or DRAWS: $UDRC_PROD"
            udrc_prod_id=1
         ;;
      esac
   else

      dbgecho "Probably not a NW Digital Radio product: $FIRM_VENDOR"
      udrc_prod_id=1
   fi

   if [ udrc_prod_id != 0 ] && [ udrc_prod_id != 1 ] ; then
      if (( UDRC_ID == udrc_prod_id )) ; then
         dbgecho "Product ID match: $udrc_prod_id"
      else
         echo "Product ID MISMATCH $UDRC_ID : $udrc_prod_id"
         udrc_prod_id=1
      fi
   fi
   dbgecho "Found HAT for ${PROD_ID_NAMES[$UDRC_ID]} with product ID: $UDRC_ID"
else
   # RPi HAT ID EEPROM may not have been programmed in engineering samples
   # or there is no RPi HAT installed.
   udrc_prod_id=0
fi

dbgecho "Finished udrc/draws id check: $udrc_prod_id"
return $udrc_prod_id
}

nwdr_id_check() {

    # Verify a UDRC HAT is installed
    id_check
    id_check_ret=$?
    if [ $id_check_ret -eq 0 ] || [ $id_check_ret -eq 1 ] ; then
        echo "No UDRC or DRAWS found, id_check=$id_check_ret exiting ..."
        exit 1
    fi
}

# function nwdr_gpio_set
# Validate channel location
# Set correct PTT gpio for channel 0 or 1
# DRAWS Hat has channel 0 on left & channel 1 on right connector

nwdr_gpio_set() {
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
}

nwdr_ptt_on() {
    # Enable PTT
    gpio=$1
    gpio -g mode $gpio out
    gpio -g write $gpio 1
}

nwdr_ptt_off() {
    # Turn off PTT
    gpio=$1
    gpio -g write $gpio 0
}

#  Build a packet for CM108 HID to turn GPIO bit on or off.
#  Packet is 4 bytes, preceded by a 'report number' byte
#  0x00 report number
#  Write data packet (from CM108 documentation)
#  byte 0: 00xx xxxx     Write GPIO
#  byte 1: xxxx dcba     GPIO3-0 output values (1=high)
#  byte 2: xxxx dcba     GPIO3-0 data-direction register (1=output)
#  byte 3: xxxx xxxx     SPDIF
usb_ptt_on() {

    gpio=$1
    iomask=$((1 << (gpio - 1) ))
    iodata=$((1 << (gpio - 1) ))

    # echo options
    #    -n   do not output the trailing newline
    #    -e   enable interpretation of backslash escapes

#    exec 5<> /dev/hidraw2
#    echo -n -e \\x00\\x00\\x01\\x01\\x00 >&5

    # report number, HID output report, GPIO state, data direction
    echo -n -e \\x00\\x00\\x${iomask}\\x${iodata}\\x00 > /dev/hidraw2
#   echo -n -e \\x00\\x00\\x04\\x04\\x00 > /dev/hidraw2

#    exec 5>&-
}
usb_ptt_off() {
    gpio=$1
    iomask=$((1 << (gpio - 1) ))
    iodata=0
    # report number, HID output report, GPIO state, data direction
    echo -n -e \\x00\\x00\\x${iomask}\\x${iodata}\\x00 > /dev/hidraw2
#   echo -n -e \\x00\\x00\\x04\\x00\\x00 > /dev/hidraw2
}

# ===== main

PROGLIST="gpio sox aplay"
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
fi

dbgecho "Verify required programs"
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
   dbgecho "Debian packages: for aplay install alsa-utils, for sox install sox, for gpio install wiringpi"
   sudo apt-get -y -q install alsa-utils sox
   # Need wiringPi version 2.52 for Raspberry Pi 4 which is not yet in Debian repos.
   wget -P /usr/local/src https://project-downloads.drogon.net/wiringpi-latest.deb
   sudo dpkg -i /usr/local/src/wiringpi-latest.deb
fi

dbgecho "Parse command line args"
# Command line args are passed with a dash & single letter
#  See usage function

while [[ $# -gt 0 ]] ; do
key="$1"

case $key in
   -f|--frequency)
      freq="$2"
      shift # past argument
   ;;

   -l|--length)
      tone_length="$2"
      shift # past argument
   ;;

   -c|--connector)
      connector="$2"
      shift # past argument
   ;;
   -D|--device)
      device="$2"
      shift # past argument
      if [ "$device" = "usb"] ; then
          NWDR=false
      elif  [ "$device" = "udrc" ] ; then
          NWDR=true
      else
          echo "Invalid device name: $device, default to device=udrc"
      fi
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

if [ $NWDR = "true" ] ; then
    nwdr_id_check
    nwdr_gpio_set
fi

# Validate tone frequency
if [ "$freq" -ge 10 -a "$freq" -le 20000 ]; then
  REPLY=1;
else
  echo "Tone Frequency $freq out of range (10 - 20000)"
  usage
  exit 1
fi

# Need path to ax25-stop script
# - $USER variable should be set
# Sox will NOT work if direwolf or any other sound card program is running
pid=$(pidof direwolf)
if [ $? -eq 0 ] ; then
   echo "Direwolf is running, with a pid of $pid"
   echo "Stopping this process"
   sudo /home/$USER/bin/ax25-stop
fi

wavefile="$freq$wavefile_basename"
echo "Using tone: $freq (wave file name: $wavefile) for duration $tone_length & $connector connector using gpio: $gpio_pin"

if [ ! -f "$wavefile" ] ; then       # Check if file exists.
   echo "Generating wavefile: $wavefile with duration of $tone_length seconds.";
   sox -n -r 48000 $wavefile synth $tone_length sine $freq sine $freq
   echo "wavgen exit code: $?"
else
   if [ $tone_length -eq $default_tone_length ] ; then
      echo "Found existing wav file: $wavefile"
   else
      echo
      echo "=== Found existing wav file: $wavefile and tone length is not default $default_tone_length seconds."
      echo "May want to delete existing wavefile $wavefile to create a different tone duration"
      echo
   fi
fi

echo "If using devcal from Svxlink make sure devcal line has -f$freq"
echo "Using PTT GPIO $gpio_pin with tone of $freq Hz"

if [ $NWDR = "true" ] ; then
    nwdr_ptt_on $gpio_pin
    SND_DEVICE="udrc"
else
    usb_ptt_on 3
    SND_DEVICE="Device"
fi

aplay -vv -D plughw:CARD="$SND_DEVICE",DEV=0 $wavefile
#aplay -vv -D hw:CARD="$SND_DEVICE",DEV=0 $wavefile
#aplay -vv -D "plughw:1,0" $wavefile
dbgecho "Return code from aplay: $?"

if [ $NWDR = "true" ] ; then
    nwdr_ptt_off $gpio_pin
else
    usb_ptt_off 3
fi

echo "Is carrier turned off?"

exit 0
