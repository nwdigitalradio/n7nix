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
DEBUG=

if [[ $# -gt 0 ]] ; then
    DEBUG=1
fi

FILES=/dev/hidraw*
for f in $FILES ; do
  HID_FILE=${f##*/}
  if [ -e /sys/class/hidraw/${HID_FILE}/device/uevent ] ; then
      DEVICE="$(cat /sys/class/hidraw/${HID_FILE}/device/uevent | grep HID_NAME | cut -d '=' -f2)"
      if [ ! -z $DEBUG ] ; then
          grep -q "C-Media" <<< $DEVICE
          if [ $? -eq 0 ] ; then
              echo "Using HID device: $HID_FILE"
	      break
          fi
      fi
      printf "%s \t %s\n" $HID_FILE "$DEVICE"
  fi
done
