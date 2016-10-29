#!/bin/bash
#
# Arguments are parsed by position
#  arg 1 is frequency of tone in Hz
#  arg 2 is anything & will enable the second port (mini din-6)
#
# Examples:
# On a UDRC II, send 2200 Hz sine wave out mini din-6 connector
# ./measure_deviate.sh 2200 -
#
# On a UDRC II, send 1200 Hz sine wave out HD-15 connector
# ./measure_deviate.sh 1200
#
# Uncomment this statement for debug statements
# DEBUG=1

firmware_prodfile="/sys/firmware/devicetree/base/hat/product"
firmware_prod_idfile="/sys/firmware/devicetree/base/hat/product_id"

# Default to using this tone in HZ
freq=2200
wavefile_basename="hzsin.wav"
wavefile="$freq$wavefile_basename"
#default to UDRC II, channel 0
gpio_pin=12

myname="`basename $0`"

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

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

# Verify a UDRC HAT is installed
id_check

dbgecho "Verify required programs"
# Verify required programs are installed
for prog_name in `echo ${PROGLIST}` ; do

   type -P $prog_name &> /dev/null
   if [ $? -ne 0 ] ; then
      echo "$myname: Need to Install $prog_name program"
      EXITFLAG=true
   fi
done
if [ "$EXITFLAG" = "true" ] ; then
   echo "Debian packages: aplay > alsa-utils, sox > sox"
   echo "gpio program found here: http://wiringpi.com/download-and-install/"
   echo "Exiting"
   exit 1
fi

dbgecho "Parse number of agrs"
# Check number of command line args
#
## No args  - default tone with freq 2200 and PTT on gpio 12
## One arg  - expect tone frequency between 10 & 20,000 Hz
## Two args - expect valid tone freq as first arg and anything else to
##            select port 1 (0,1)
case $# in

0)
   echo "No arguments using this wave file: $wavefile"
;;

1)
   # Validate tone frequency
   if [ "$1" -ge 10 -a "$1" -le 20000 ]; then
     REPLY=1;
   elif
     echo "Frequency $1 out of range (10 - 20000)"; then
     exit 1
   fi
   # Set frequency from command line arg
   freq=$1
;;
2)
   # use channel 1 PTT gpio
   gpio_pin=23
;;

*)
   echo "Too many arguments on command line ($#)"
   exit 1
;;

esac

wavefile="$freq$wavefile_basename"

if [ ! -f "$wavefile" ] ; then       # Check if file exists.
   echo "Generating wavefile: $wavefile.";
   sox -n -r 48000 $wavefile synth 30 sine $freq sine $freq
   echo "wavgen exit code: $?"
else
   echo "Found existing wav file: $wavefile"
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
