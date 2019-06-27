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
9020e0)
   echo " Pi 3 Model A+, Rev 1.0, Mfg by Sony UK"
   HAS_WIFI=true
;;
a01040)
   echo " Pi 2 Model B, Rev 1.0, Mfg by Sony UK"
;;
a01041)
   echo " Pi 2 Model B, Rev 1.1, Mfg by Sony UK"
;;
a02082)
   echo " Pi 3 Model B, Rev 1.2, Mfg by Sony UK"
   HAS_WIFI=true
;;
a020d3)
   echo " Pi 3 Model B+,  Rev 1.3, Mfg by Sony UK"
   HAS_WIFI=true
;;
a21041)
   echo " Pi 2 Model B, Rev 1.1, Mfg by Embest"
;;
a22042)
   echo " Pi 2 Model B with BCM2837, Rev 1.2, Mfg by Embest"
;;
a22082)
   echo " Pi 3 Model B, Rev 1.2, Mfg by Embest"
   HAS_WIFI=true
;;
a32082)
   echo " Pi 3 Model B, Rev 1.2, Mfg by Sony Japan"
   HAS_WIFI=true
;;
a52082)
   echo " Pi 3 Model B, Rev 1.2, Mfg by Stadium"
   HAS_WIFI=true
;;
a22083)
   echo " Pi 3 Model B, Rev 1.3, Mfg by Embest"
   HAS_WIFI=true
;;
a03111)
   echo " Pi 4 Model B,  Rev 1.1, 1GB mem, Mfg by Sony UK"
   HAS_WIFI=true
;;
b03111)
   echo " Pi 4 Model B,  Rev 1.1, 2GB mem, Mfg by Sony UK"
   HAS_WIFI=true
;;
c03111)
   echo " Pi 4 Model B,  Rev 1.1, 4GB mem, Mfg by Sony UK"
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
