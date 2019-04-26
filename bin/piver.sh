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
   echo " Pi 2 Model B Mfg by Sony UK"
;;
a01041)
   echo " Pi 2 Model B Mfg by Sony UK"
;;
a21041)
   echo " Pi 2 Model B Mfg by Embest"
;;
a22042)
   echo " Pi 2 Model B with BCM2837 Mfg by Embest"
;;
a02082)
   echo " Pi 3 Model B Mfg by Sony UK"
   HAS_WIFI=true
;;
a22082)
   echo " Pi 3 Model B Mfg by Embest"
   HAS_WIFI=true
;;
a32082)
   echo " Pi 3 Model B Mfg by Sony Japan"
   HAS_WIFI=true
;;
a52082)
   echo " Pi 3 Model B Mfg by Stadium"
   HAS_WIFI=true
;;
a020d3)
   echo " Pi 3 Model B+ Mfg by Sony UK"
   HAS_WIFI=true
;;
9020e0)
   echo " Pi 3 Model A+ Mfg by Sony UK"
   HAS_WIFI=true
;;
*)
   echo "Unknown pi version: $piver"
   echo "Model: $(tr -d '\0' </proc/device-tree/model)"
   grep "Revision" $CPUINFO_FILE
;;
esac

retcode=1
if $HAS_WIFI ; then
   echo " Has WiFi"
   retcode=0
fi
exit $retcode
