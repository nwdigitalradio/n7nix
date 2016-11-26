#!/bin/bash
#
# Usage:
#   measure_deviate.sh [-f _tone_frequency_][-c _connector_type_][-l _tone_duration_][-h]
#
# Examples:
# On a UDRC II, send 2200 Hz sine wave out mini din-6 connector
#   for 30 seconds
# ./measure_deviate.sh -f 2200 -c din6 -l 30
#
# On a UDRC II, send 1200 Hz sine wave out HD-15 connector
#   for 30 seconds
# ./measure_deviate.sh -f 1200 -c hd15
#

scriptname="`basename $0`"

firmware_prodfile="/sys/firmware/devicetree/base/hat/product"
firmware_prod_idfile="/sys/firmware/devicetree/base/hat/product_id"

# Default to using this tone in HZ
freq=2200
tone_length=30
default_tone_length=30
connector="hd15"
wavefile_basename="hzsin.wav"
wavefile="$freq$wavefile_basename"
#default to UDRC II, channel 0
UDRCII=true
gpio_pin=12

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT
# ===== function usage
function usage() {
   echo "Usage: $scriptname [-f <tone_frequency][-c <connector>[-l <tone_duration>][-h]" >&2
   echo "   -f tone frequency in Hz (10 - 20000), default: 2200"
   echo "   -c connector type either din6 or hd15, default: hd15"
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
	gpio -g write 12 0
	gpio -g write 23 0
	exit
}

# ===== function udrc id_check

function id_check() {
# Initialize to EEPROM not found
udrc_prod_id=0
dbgecho "Starting udrc id check"

# Does firmware file exist
if [ -f $firmware_prodfile ] ; then
   # Read product file
   UDRC_PROD="$(cat $firmware_prodfile)"
   sizeprodstr=${#UDRC_PROD}
   dbgecho "UDRC_PROD: $UDRC_PROD, size: $sizeprodstr"
   if (( $sizeprodstr < 34 )) ; then
      dbgecho "Probably not a Universal Digital Radio Controller: $UDRC_PROD"
      udrc_prod_id=1
   elif [ "${UDRC_PROD:0:34}" == "Universal Digital Radio Controller" ] ; then
      dbgecho "Definitely some kind of UDRC"
   else
      echo "Found something but not a UDRC: $UDRC_PROD"
      exit 1
   fi

   # get last 2 characters in product file
   UDRC_PROD=${UDRC_PROD: -2}
   # Read product id file
   UDRC_ID="$(cat $firmware_prod_idfile)"
   #get last character in product id file
   UDRC_ID=${UDRC_ID: -1}
   udrc_prod_id=$UDRC_ID

   dbgecho "Product: $UDRC_PROD, Id: $UDRC_ID"
   if [ "$UDRC_PROD" == "II" ] && [ "$UDRC_ID" == "3" ] ; then
      dbgecho "Found a UDRC II"
      UDRCII=true
   elif [ "$UDRC_PROD" == "er" ] && [ "$UDRC_ID" == "2" ] ; then
      dbgecho "Found an original UDRC"
      UDRCII=false
   else
      dbgecho "No UDRC found"
      exit 1
   fi

else
   # RPi HAT ID EEPROM may not have been programmed in engineering samples
   # or there is no RPi HAT installed.
   udrc_prod_id=0
fi
dbgecho "Finished udrc id check"
return $udrc_prod_id
}

# ===== main

PROGLIST="gpio sox aplay"
EXITFLAG=false

dbgecho "Verify required programs"
# Verify required programs are installed
for prog_name in `echo ${PROGLIST}` ; do
   type -P $prog_name &> /dev/null
   if [ $? -ne 0 ] ; then
      echo "$scriptname: Need to Install $prog_name program"
      if [ "$prog_name" == "gpio" ] ; then
         echo
         echo "=== Installing WiringPI for gpio program"
	 git clone git://git.drogon.net/wiringPi
	 cd wiringPi
	./build
	echo "=== Finished installing WiringPI"
      else
         EXITFLAG=true
      fi
   fi
done
if [ "$EXITFLAG" = "true" ] ; then
   echo "Debian packages: for aplay install alsa-utils, for sox install sox"
   echo "Exiting"
   exit 1
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

# Verify a UDRC HAT is installed
id_check

# Validate tone frequency
if [ "$freq" -ge 10 -a "$freq" -le 20000 ]; then
  REPLY=1;
else
  echo "Tone Frequency $freq out of range (10 - 20000)"
  usage
  exit 1
fi

# Validate connector type
case $connector in
   din6)
      # use channel 0 PTT gpio
      if [ "$UDRCII" == "true" ] ; then
      # uses audio channel 1 PTT gpio
         gpio_pin=23
      else
         # uses audio channel 0 PTT gpio
         gpio_pin=12
      fi
   ;;
   hd15)
      # uses audio channel 0 PTT gpio
      gpio_pin=12
   ;;
   *)
      echo "Wrong connector type specified: $connector"
      usage
      exit 1
   ;;
esac

# Won't work if direwolf or any other sound card program is running
pid=$(pidof direwolf)
if [ $? -eq 0 ] ; then
   echo "Direwolf is running, with a pid of $pid"
   echo "As root kill this process"
   exit 1
fi

wavefile="$freq$wavefile_basename"
echo "Using tone: $freq (wave file name: $wavefile) for duration $tone_length & connector: $connector using gpio: $gpio_pin"

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

# Enable PTT
gpio -g mode $gpio_pin out
gpio -g write $gpio_pin 1

#aplay -vv -D hw:CARD=udrc,DEV=0 $wavefile
aplay -vv -D "plughw:1,0" $wavefile
dbgecho "Return code from aplay: $?"

# Turn off PTT
gpio -g write $gpio_pin 0

echo "Is carrier turned off?"

exit 0
