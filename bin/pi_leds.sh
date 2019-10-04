#!/bin/bash
# Change trigger method for one of the RPi leds

DEBUG=1
scriptname="`basename $0`"
# Set led to act on
LED_N="0"

# Read current trigger method
trigger=$(cat /sys/class/leds/led$LED_N/trigger | cut -d '[' -f 2 | cut -d ']' -f1)

## ============ functions ============

function dbgecho  { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

##### function Display program help info
#
usage () {
	(
	echo "Usage: $scriptname [heartbeat][mmc]"
        ) 1>&2
        exit 1
}

##### main

# Check for any command line arguments
if [[ $# -gt 0 ]] ; then

    key="$1"
    echo "Found argument $key"

    case $key in
        heartbeat)
            dbgecho "Changing led trigger from $trigger to heartbeat blink"
             echo heartbeat | sudo tee /sys/class/leds/led$LED_N/trigger
        ;;
        mmc)
            dbgecho "Changing led trigger from $trigger to ssd card activity"
            echo mmc0 | sudo tee /sys/class/leds/led$LED_N/trigger
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
else
    echo "led$LED_N triggers on: $trigger"
fi
