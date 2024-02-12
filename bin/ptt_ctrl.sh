#!/bin/bash
#
# Simple script to control PTT gpios.
# Turn PTT gpio on & off & check result
#
# Turn right connector PTT on
# ptt_ctrl.sh -r on
#
# Turn right connector PTT off
# ptt_ctrl.sh -r off
#
# Turn left connector PTT on
#  ptt_ctrl.sh -l on
#
# Turn left connector PTT off
#  ptt_ctrl.sh -l off
#
# Read left connector PTT
#  ptt_ctrl.sh -l -c

#DEBUG=

scriptname="`basename $0`"

# default to READ gpio
b_gpioWRITE=false
# default to turn gpio OFF
b_gpioON=false
# default to NOT toggle gpio state
b_gpioTOGGLE=false

GPIO_PATH="/sys/class/gpio"


function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# Functions for sysfs GPIO

# Function exportPin
#  enumerate gpio in sysfs
exportPin()
{
  if [ ! -e $GPIO_PATH/gpio$1 ]; then
    echo "$1" > $GPIO_PATH/export
  fi
}

# function makepin_read
function makepin_read() {
    echo "in" > $GPIO_PATH/gpio$1/direction
}

# function makepin_write
function makepin_write() {
    echo "out" > $GPIO_PATH/gpio$1/direction
}

function setGPIO () {
    echo $2 > $GPIO_PATH/gpio$1/value
}

function getGPIO () {
    return $(cat $GPIO_PATH/gpio$1/value)
}

# ===== function sysfs
# Use sysfs routines
function sysfs() {

    dbgecho "sysfs test: read gpio 12 direction $(cat $GPIO_PATH/gpio$gpio_num/direction), value $(cat $GPIO_PATH/gpio$gpio_num/value)"

    # Set gpio mode to output
    makepin_write $gpio_num

    if $b_gpioTOGGLE ; then
        # Get current state
        gpio_state="$(getGPIO $gpio_num)"
        dbgecho "sysfs gpio state=$gpio_state"
        if [ "$gpio_state" = 0 ] ; then
            dbgecho "sysfs Turn PTT on gpio: $gpio_num"
            setGPIO $gpio_num 1
        else
            dbgecho "sysfs Turn PTT off gpio: $gpio_num"
            setGPIO $gpio_num 0
        fi
        exit
    fi

    if $b_gpioWRITE ; then
        if $b_gpioON ; then
            setGPIO $gpio_num 1
            state="on"
        else
            setGPIO $gpio_num 0
            state="off"
        fi
        echo "sysfs Turn gpio $gpio_num $state"
    else
        gpio_value=$(getGPIO $gpio_num)
	echo -n "sysfs Read gpio: $gpio_num = $gpio_value"
   fi
}

# ===== function wiringpi
# Use wiringpi routines
function wiringpi() {
    # Set gpio mode to output
    gpio -g mode $gpio_num out

    if $b_gpioTOGGLE ; then
        # Get current state
        gpio_state=$(gpio -g read $gpio_num)
        dbgecho "WiringPI gpio state=$gpio_state"
        if [ "$gpio_state" = 0 ] ; then
            dbgecho "WiringPI Turn PTT on gpio: $gpio_num"
            gpio -g write $gpio_num 1
        else
            dbgecho "WiringPI Turn PTT off gpio: $gpio_num"
            gpio -g write $gpio_num 0
        fi
        exit
    fi

    if $b_gpioWRITE ; then
        if $b_gpioON ; then
            gpio -g write $gpio_num 1
            state="on"
        else
            gpio -g write $gpio_num 0
            state="off"
        fi
        echo "WiringPI Turn gpio $gpio_num $state"
    else
        echo -n "WiringPI Read gpio: $gpio_num = "
        gpio -g read $gpio_num
   fi
}

# Function libgpiod

# gpiod is a set of tools for interacting with the linux GPIO character
# device that uses libgpiod library. Since linux 4.8 the GPIO sysfs
# interface is deprecated. User space should use the character device
# instead. libgpiod encapsulates the ioctl calls and data structures
# behind a straightforward API.

# * gpiodetect - list all gpiochips present on the system, their names,
#      labels and number of GPIO lines
#
# * gpioinfo - list all lines of specified gpiochips, their names,
#      consumers, direction, active state and additional flags
#
# * gpioget    - read values of specified GPIO lines
#
# * gpioset - set values of specified GPIO lines, potentially keep the
#      lines exported and wait until timeout, user input or signal
#     $ gpioset GPIO23=1
#
# * gpiofind   - find the gpiochip name and line offset given the line name

# * gpiomon - wait for events on GPIO lines, specify which events to
#      watch, how many events to process before exiting or if
#     the events should be reported to the console
#
# For left & right channels
# gpioset gpiochip4 12=0
# gpioset gpiochip4 23=0
# gpioset gpiochip4 12=1
# gpioset gpiochip4 23=1
#
# Running gpioget gpiochip4 12
#  will turn the gpio into read only

function libgpiod() {

    if $b_gpioTOGGLE ; then
        echo "Toggle not supported for gpiod"
        exit
    fi

    if $b_gpioWRITE ; then
        if $b_gpioON ; then
            gpioset gpiochip4 $gpio_num=1
            state="on"
        else
            gpioset gpiochip4 $gpio_num=0
            state="off"
        fi
        echo "gpiod Turn gpio $gpio_num $state"
    else
        echo -n "gpiod Read gpio: $gpio_num = "
        gpio_value=$(gpioget gpiochip4 $gpio_num)
	echo -n "gpiod Read gpio: $gpio_num = $gpio_value"
   fi
}

# ===== function usage

function usage() {
   echo "Usage: $scriptname [-l][-r][-on][-off][-c][-h]" >&2
   echo "   -l | --left    Select left connector gpio"
   echo "   -r | --right   Select right connector gpio"
   echo "   -on  | on      Turn selected gpio ON"
   echo "   -off | off     Turn selected gpio OFF"
   echo "   -t | --toggle  Toggle PTT state"
   echo "   -c | --check   Check gpio state ie. read gpio"
   echo "   -d | --debug   Turn debug on"
   echo "   -m | --method <wiring sysfs gpiod>"
   echo "   -h             display this message"
}

# ===== main

#
# Determine which GPIO method will work
#
# WiringPi has a hard requirement on finding string "hardware" in cpuinfo
grep -iq "hardware" /proc/cpuinfo
if [ $? -eq 1 ] ; then
    echo
    echo "WiringPi will NOT run on this platform, try sysfs"
    # Set default method
    ptt_method="sysfs"
    if [ ! -e /sys/class/gpio/gpio12 ] ; then
        echo "sysfs will not run on this platform, try libgpiod"
	ptt_method="gpiod"
    fi
else
    ptt_method="wiring"
fi

echo "Using gpio method: $ptt_method"
echo


# Set default connector to left
gpio_num=12


# if there are any args then parse them
while [[ $# -gt 0 ]] ; do
   key="$1"

   case $key in
      -l|--left)
	 gpio_num=12
	 ;;
      -r|--right)
	 gpio_num=23
         ;;
      -on|-On|-ON|on|On|ON)
         b_gpioON=true
         b_gpioWRITE=true
         ;;
      -off|-Off|-OFF|off|Off|OFF)
         b_gpioON=false
         b_gpioWRITE=true
         ;;
      -t |--toggle)
         b_gpioTOGGLE=true
         ;;
      -d|--debug)
         DEBUG=1
         dbgecho "Debug flag set"
         ;;
      -c|--check)
         b_gpioWRITE=false
         ;;
      -m|--method)
          ptt_method="$2"
	  echo "Will try gpio method $ptt_method"
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

dbgecho "Options: set gpio: $gpio_num, state: On=$b_gpioON, action: Write=$b_gpioWRITE"

case $ptt_method in
    wiring)
        wiringpi
    ;;
    sysfs)
        sysfs
    ;;
    gpiod)
       libgpiod
    ;;
    *)
        echo "Unknown method: $ptt_method"
	echo " Must be one of: wiring, sysfs or gpiod"
    ;;
esac



