#!/bin/bash
#
# Display Raspberry Pi model & revision number from /proc/cpuinfo
# If any command line arguments detected the short version is displayed
#
# Hardware History
# https://elinux.org/RPi_HardwareHistory
#
# RPi latest Revision Codes
# https://www.raspberrypi.org/documentation/hardware/raspberrypi/revision-codes/README.md
#

CPUINFO_FILE="/proc/cpuinfo"
HAS_WIFI=false
QUIET_MODE=false

# Check if there are any args on command line
if (( $# != 0 )) ; then
    QUIET_MODE=true
fi

# Get CPU clock frequency
cpu_clk=$(vcgencmd measure_clock arm | cut -f2 -d'=')
cpu_clk=${cpu_clk::-6}

# This method works as well
#piver="$(grep "Revision" $CPUINFO_FILE | cut -d':' -f2- | tr -d '[[:space:]]')"

piver="$(grep "Revision" $CPUINFO_FILE)"
piver="$(echo -e "${piver##*:}" | tr -d '[[:space:]]')"

case $piver in
9020e0)
   VERSION_STRING=" Pi 3 Model A+, Rev 1.0, Mfg by Sony UK, $cpu_clk MHz"
   HAS_WIFI=true
;;
a01040)
   VERSION_STRING=" Pi 2 Model B, Rev 1.0, Mfg by Sony UK, $cpu_clk MHz"
;;
a01041)
   VERSION_STRING=" Pi 2 Model B, Rev 1.1, Mfg by Sony UK, $cpu_clk MHz"
;;
a02082)
   VERSION_STRING=" Pi 3 Model B, Rev 1.2, Mfg by Sony UK, $cpu_clk MHz"
   HAS_WIFI=true
;;
a020d3)
   VERSION_STRING=" Pi 3 Model B+, Rev 1.3, Mfg by Sony UK, $cpu_clk MHz"
   HAS_WIFI=true
;;
a21041)
   VERSION_STRING=" Pi 2 Model B, Rev 1.1, Mfg by Embest, $cpu_clk MHz"
;;
a22042)
   VERSION_STRING=" Pi 2 Model B with BCM2837, Rev 1.2, Mfg by Embest, $cpu_clk MHz"
;;
a22082)
   VERSION_STRING=" Pi 3 Model B, Rev 1.2, Mfg by Embest, $cpu_clk MHz"
   HAS_WIFI=true
;;
a32082)
   VERSION_STRING=" Pi 3 Model B, Rev 1.2, Mfg by Sony Japan, $cpu_clk MHz"
   HAS_WIFI=true
;;
a52082)
   VERSION_STRING=" Pi 3 Model B, Rev 1.2, Mfg by Stadium, $cpu_clk MHz"
   HAS_WIFI=true
;;
a22083)
   VERSION_STRING=" Pi 3 Model B, Rev 1.3, Mfg by Embest, $cpu_clk MHz"
   HAS_WIFI=true
;;
a03111)
   VERSION_STRING=" Pi 4 Model B, Rev 1.1, 1GB mem, Mfg by Sony UK, $cpu_clk MHz"
   HAS_WIFI=true
;;
b03111)
   VERSION_STRING=" Pi 4 Model B, Rev 1.1, 2GB mem, Mfg by Sony UK, $cpu_clk MHz"
   HAS_WIFI=true
;;
b03112)
   VERSION_STRING=" Pi 4 Model B, Rev 1.2, 2GB mem, Mfg by Sony UK, $cpu_clk MHz"
   HAS_WIFI=true
;;
b03114)
   VERSION_STRING=" Pi 4 Model B, Rev 1.4, 2GB mem, Mfg by Sony UK, $cpu_clk MHz"
   HAS_WIFI=true
;;
c03111)
   VERSION_STRING=" Pi 4 Model B, Rev 1.1, 4GB mem, Mfg by Sony UK, $cpu_clk MHz"
   HAS_WIFI=true
;;
c03112)
   VERSION_STRING=" Pi 4 Model B, Rev 1.2, 4GB mem, Mfg by Sony UK, $cpu_clk MHz"
   HAS_WIFI=true
;;
c03114)
   VERSION_STRING=" Pi 4 Model B, Rev 1.4, 4GB mem, Mfg by Sony UK, $cpu_clk MHz"
   HAS_WIFI=true
;;
d03114)
   VERSION_STRING=" Pi 4 Model B, Rev 1.4, 8GB mem, Mfg by Sony UK, $cpu_clk MHz"
   HAS_WIFI=true
;;
c03130)
   VERSION_STRING=" Pi 400, Rev 1.0, 4GB mem, Mfg by Sony UK, $cpu_clk MHz"
   HAS_WIFI=true
;;
*)
   echo "Unknown pi version: $piver"
   echo "Model: $(tr -d '\0' </proc/device-tree/model)"
   grep "Revision" $CPUINFO_FILE
   exit 1
;;
esac

retcode=1
if $QUIET_MODE ; then
    SHORT_STRING=$(echo "$VERSION_STRING" | cut -f1 -d',')
    echo "$SHORT_STRING"
else
    WIFI_STRING=
    if $HAS_WIFI ; then
        WIFI_STRING="with WiFi"
        retcode=0
    fi

    echo "$VERSION_STRING $WIFI_STRING"
fi
exit $retcode
