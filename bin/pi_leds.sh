#!/bin/bash
#
# There are two LEDs on a Raspberry Pi
#  PWR
#  ACT
#
# Change trigger method for the activity RPi led
# How to turn off the power led
DEBUG=
VERSION=1.1

scriptname="`basename $0`"
# Select led 0=green activity LED, 1=red power LED
LED_N="0"

## ============ functions ============

function dbgecho  { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function get_trigger

function get_trigger() {

    DIR_LED="$DIR_LED0"
    if [ "$LED_N" = 1 ] ; then
	DIR_LED="$DIR_LED1"
    fi

    # Read current trigger method
    trigger=$(cat $DIR_LED/trigger | cut -d '[' -f 2 | cut -d ']' -f1)
}

# ===== function get_brightness
function get_brightness() {

    DIR_LED="$DIR_LED0"
    if [ "$LED_N" = 1 ] ; then
	DIR_LED="$DIR_LED1"
    fi

    # Read current brightness value
    brightness=$(cat $DIR_LED/brightness)
}

##### function Display program help info
#
usage () {
	(
	echo "$scriptname version: $VERSION"
	echo "Usage: $scriptname [-l <led_id>][heartbeat][mmc][timer][on][off][both][default]"
        ) 1>&2
        exit 1
}

##### main

# Read current trigger method
#trigger=$(cat /sys/class/leds/led$LED_N/trigger | cut -d '[' -f 2 | cut -d ']' -f1)


DIR_LED0="/sys/class/leds/led0"
DIR_LED1="/sys/class/leds/led1"

dbgecho "check existence of led directory: $DIR_LED0"
if [ ! -d $DIR_LED0 ] ; then
    dbgecho "Directory: $DIR_LED0 not found"
    DIR_LED0="/sys/class/leds/ACT"
    DIR_LED1="/sys/class/leds/PWR"
fi

# Check for any command line arguments
if [[ $# -gt 0 ]] ; then

while [[ $# -gt 0 ]] ; do
key="$1"

    key="$1"
    dbgecho "Found argument $key"

    case $key in
        -l)
	    # Select either led 0 or 1
	    LED_N=$2
            shift # past argument
	    if [ $LED_N -ne 0 ] && [ $LED_N -ne 1 ] ; then
	        echo "Invalid LED id, must be either 0 or 1"
		usage
	    fi
	;;
        timer)
            get_trigger
            echo "Changing led trigger from $trigger to timer"
            echo timer | sudo tee $DIR_LED/trigger > /dev/null
        ;;
        heartbeat)
            get_trigger
            echo "Changing led trigger from $trigger to heartbeat blink"
            echo heartbeat | sudo tee $DIR_LED/trigger > /dev/null
        ;;
        mmc)
            # Read current trigger method
            get_trigger

            echo "Changing led trigger from $trigger to ssd memory card activity"
            echo mmc0 | sudo tee $DIR_LED/trigger > /dev/null
        ;;
	on)
            get_brightness
	    if [ $LED_N = 1 ] ; then
                echo "Changing led brightness from $brightness to full on"
                echo 255 | sudo tee $DIR_LED1/brightness > /dev/null
		echo "default-on" | sudo tee $DIR_LED1/trigger > /dev/null
            else
                # Read current trigger method
                get_trigger

                echo "Changing led trigger from $trigger to heartbeat"
                echo heartbeat | sudo tee $DIR_LED0/trigger  > /dev/null
	    fi
	;;
	off)
	    if [ $LED_N = 1 ] ; then
                # Read current brightness value
                get_brightness
                echo "Changing led brightness from $brightness to off"
                echo 0 | sudo tee $DIR_LED1/brightness  > /dev/null
            else
                # Read current trigger method
                get_trigger
                echo "Changing led trigger from $trigger to none"
                echo none | sudo tee $DIR_LED0/trigger > /dev/null
	    fi
	;;
	both)
	    # Alternate blinking of both LEDS
	    LED_N=0
            echo timer | sudo tee $DIR_LED0/trigger > /dev/null

	    LED_N=1
	    # to alternate the blinking turn one led off for a second
	    # Turn off the red led
            echo 0 | sudo tee $DIR_LED1/brightness  > /dev/null
            echo "Changing led trigger for both LEDS to timer"
            sleep 0.5
	    # blink red led
            echo timer | sudo tee $DIR_LED1/trigger > /dev/null
	;;
	default)
	    # led0 triggered by mmc0, led1 on steady
            LED_N=0
            echo mmc0 | sudo tee $DIR_LED0/trigger > /dev/null

            LED_N=1
            echo 255 | sudo tee $DIR_LED1/brightness > /dev/null
            echo "default-on" | sudo tee $DIR_LED1/trigger > /dev/null
	    echo "Changing led trigger to default (led0 green trigger mmc0, led1 red on steady)"
	;;
        -d|--debug)
            DEBUG=1
            echo "Debug mode on"
        ;;

        -h)
            usage
            exit 1
        ;;
        *)
            echo "Undefined argument: $key"
            usage
            exit 1
        ;;
    esac
shift # past argument or value
done

else
    LED_N=0
    DIR_LED="$DIR_LED0"

    get_trigger
    get_brightness
    echo "led$LED_N (ACT) triggers on: $trigger, brightness: $brightness"


    LED_N=1
    DIR_LED="$DIR_LED1"

    get_trigger
    get_brightness
    echo "led$LED_N (PWR) triggers on: $trigger, brightness: $brightness"
fi

exit 0
