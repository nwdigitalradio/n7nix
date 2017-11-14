#!/bin/bash
#
# If UDRC is the HAT then these GPIOs are available:
#  BCM  wPi     cut
#  16  gpio.27  11
#  17  gpio. 0   5

gpio_num="17"
wpi_num="gpio. 0"

scriptname="`basename $0`"

# ===== function usage
function usage() {
   echo "Usage: $scriptname [on][off]"
   echo
}

# ===== main
mode_gpio="$(gpio readall | grep -i "$wpi_num" | cut -d "|" -f 5 | tr -d '[:space:]')"

if [ "$mode_gpio" != "OUT" ] ; then
   echo "gpio $gpio_num is in wrong mode: |$mode_gpio|, should be: OUT"
   gpio -g mode $gpio_num out
fi

arg="$1"

case $arg in
   on|On|ON)
      gpio -g write $gpio_num 1
      ;;
   off|Off|OFF)
      gpio -g write $gpio_num 0
      ;;
   ?|h|H)
      usage
      ;;
   *)
      state_gpio="$(gpio readall | grep -i "$wpi_num" | cut -d "|" -f 6 | tr -d '[:space:]')"
      state_str="off"
      if [ "$state_gpio" -eq "1" ] ; then
         state_str="on"
      fi
      echo "gpio $gpio_num is $state_str"
   ;;
esac

exit 0
