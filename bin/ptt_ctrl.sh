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

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

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

if $b_gpioTOGGLE ; then
    # Get current state
    gpio_state=$(gpio -g read $gpio_num)
    dbgecho "gpio state=$gpio_state"
    if [ "$gpio_state" = 0 ] ; then
        dbgecho "Turn PTT on gpio: $gpio_num"
        gpio -g write $gpio_num 1
    else
        dbgecho "Turn PTT off gpio: $gpio_num"
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
    echo "Turn gpio $gpio_num $state"

else
    echo -n "Read gpio: $gpio_num = "
    gpio -g read $gpio_num
fi

