#!/bin/bash
#
# Install a host access point
#
# hosts, resolv.conf /etc/network/interfaces /etc/dhcpcd.conf
DEBUG=1

scriptname="`basename $0`"
SSID="NOT_SET"

# Required pacakges
PKGLIST="hostapd dnsmasq iptables iptables-persistent"
SERVICELIST="hostapd dnsmasq"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# ===== function is_rpi3

function is_rpi3() {

CPUINFO_FILE="/proc/cpuinfo"
HAS_WIFI=0

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
a02082)
   echo " Pi 3 Model B Mfg by Sony"
   HAS_WIFI=1
;;
a22082)
   echo " Pi 3 Model B Mfg by Embest"
   HAS_WIFI=1
;;
esac

return $HAS_WIFI
}

# ===== main

echo "Install hostap on an RPi 3"

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root."
   exit 1
fi

is_rpi3
if [ $? -eq "0" ] ; then
   echo "Not running on an RPi 3 ... exiting"
   exit 1
fi

# check if packages are installed
dbgecho "Check packages: $PKGLIST"

# Fix for iptables-persistent broken
#  https://discourse.osmc.tv/t/failed-to-start-load-kernel-modules/3163/14
#  https://www.raspberrypi.org/forums/viewtopic.php?f=63&t=174648

sed -i -e 's/^#*/#/' /etc/modules-load.d/cups-filters.conf

for pkg_name in `echo ${PKGLIST}` ; do

   is_pkg_installed $pkg_name
   if [ $? -ne 0 ] ; then
      echo "$scriptname: Need to Install $pkg_name program"
      apt-get -qy install $pkg_name
   fi
done

echo "$(date "+%Y %m %d %T %Z"): hostap install script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "hostap install FINISHED"
echo
