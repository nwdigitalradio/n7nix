#!/bin/bash
#
# Source code for this script from here: (Thank You!)
# https://arvchristos.github.io/post/matching-dev-hidraw-devices-with-physical-devices/
#
# Display HID raw devices and USB audio device names
#
# For example:
# hidraw0 	 ILITEK ILITEK-TP
# hidraw1 	 ILITEK ILITEK-TP
# hidraw2 	 C-Media Electronics Inc. USB Audio Device

FILES=/dev/hidraw*
for f in $FILES
do
  FILE=${f##*/}
  DEVICE="$(cat /sys/class/hidraw/${FILE}/device/uevent | grep HID_NAME | cut -d '=' -f2)"
  printf "%s \t %s\n" $FILE "$DEVICE"
done
