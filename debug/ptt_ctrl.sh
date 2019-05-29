#!/bin/bash
#
# Simple script to control PTT gpios.
# Turn PTT gpio on & off & check result
#
# Turn right connector PTT on
# ptt_ctrl.sh -on -r
#
# Turn right connector PTT off
# ptt_ctrl.sh -off -r
#
# Turn left connector PTT on
#  ptt_ctrl.sh -on -l
#
# Turn left connector PTT off
#  ptt_ctrl.sh -off -l
#
# Read left connector PTT
#  ptt_ctrl.sh -c -l

#DEBUG=

scriptname="`basename $0`"

# default to read gpio
b_gpioWRITE=false
# default to turn gpio off
b_gpioON=false

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function usage

function usage() {
   echo "Usage: $scriptname [-l][-r][-on][-off][-c][-h]" >&2
   echo "   -l | --left    Select left connector"
   echo "   -r | --right   Select right connector"
   echo "   -on            Turn selected gpio ON"
   echo "   -off           Turn selected gpio OFF"
   echo "   -c | --check   Check gpio state ie. read gpio"
   echo "   -d | --debug   Turn debug on"
   echo "   -h             display this message"
}

# ===== main

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
      -on|-On|-ON)
         b_gpioON=true
         b_gpioWRITE=true
         ;;
      -off|-Off|OFF)
         b_gpioON=false
         b_gpioWRITE=true
         ;;
      -d|--debug)
         DEBUG=1
         dbgecho "Debug flag set"
         ;;
      -c|--check)
         b_gpioWRITE=false
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

# Set gpio mode to output
gpio -g mode $gpio_num out

if $b_gpioWRITE ; then
    if $b_gpioON ; then
        gpio -g write $gpio_num 1
        state="on"
    else
        gpio -g write $gpio_num 0
        state="off"
    fi
    echo "Turn gpio $gpio_num $state"

else
    echo -n "Read gpio: $gpio_num = "
    gpio -g read $gpio_num
fi

