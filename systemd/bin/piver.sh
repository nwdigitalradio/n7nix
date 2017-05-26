#!/bin/bash
#
# Raspberry Pi version check based on Revision number from cpuinfo

CPUINFO_FILE="/proc/cpuinfo"
HAS_WIFI=false

# This method works as well
#piver="$(grep "Revision" $CPUINFO_FILE | cut -d':' -f2- | tr -d '[[:space:]]')"

piver="$(grep "Revision" $CPUINFO_FILE)"
piver="$(echo -e "${piver##*:}" | tr -d '[[:space:]]')"

case $piver in
a01040)
   echo " Pi 2 Model B Mfg by Unknown"
;;
a01041)
   echo " Pi 2 Model B Mfg by Sony"
;;
a21041)
   echo " Pi 2 Model B Mfg by Embest"
;;
a22042)
   echo " Pi 2 Model B with BCM2837 Mfg by Embest"
;;
a02082 | a32082)
   echo " Pi 3 Model B Mfg by Sony"
   HAS_WIFI=true
;;
a22082)
   echo " Pi 3 Model B Mfg by Embest"
   HAS_WIFI=true
;;
esac

if [ "$HAS_WIFI" = "true" ] ; then
   echo " Has WiFi"
fi
exit 0
