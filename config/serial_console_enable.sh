#! /bin/bash
#
# Script to enable the serial port console which will disable bluetooth
#
# Edit 2 files:
#  /boot/config.txt
#  /boot/cmdline.txt
#
# On a Raspberry Pi 3:
# To enable serial console disable bluetooth
#  and change console to serial port ttyAMA0

grep "pi3-disable-bt" /boot/config.txt > /dev/null 2>&1
if [ $? -eq 0 ] ; then
   echo "*** Bluetooth already disabled in config.txt"
else
   echo "=== Disable bluetooth in config.txt"
# Edit config.txt
   cat << EOT >> /boot/config.txt
# Enable serial console
dtoverlay=pi3-disable-bt
EOT
fi

if (( $(cat /boot/cmdline.txt | wc -l) > 1 )) ; then
   echo "*** Warning there is more than one line in cmdline.txt"
fi

grep "console=ttyAMA0" /boot/cmdline.txt > /dev/null 2>&1
if [ $? -eq 0 ] ; then
   echo "*** Found serial console ttyAMA0 in /boot/cmdline.txt"
else
   echo " Editing cmdline.txt"
   # Edit cmdline.txt
   sed -i -e "/console/ s/console=serial0/console=ttyAMA0,115200/" /boot/cmdline.txt
fi
