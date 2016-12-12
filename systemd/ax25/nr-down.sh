#!/bin/bash
#

# is netromd running?
pidof netromd > /dev/null
if [ $? -eq 0 ]; then

   # Save NetRom routes
   /usr/local/sbin/nodesave -p /usr/local/sbin/ /var/ax25/nrsave && echo "N/R routes saved"

   # Stop NetRom
   killall netromd > /dev/null
   echo "netrom daemon stopped"
else
   echo "netrom daemon not running"
fi

echo "Detach Ax/Nr/Sp Devices"

ifconfig|grep AMPR > /tmp/ax25-config.tmp

i=0
iface=$(awk ' NR == '1' { print $1 }' /tmp/ax25-config.tmp)

while [ "$iface" != "" ] ; do
   let i=i+1
   iface=$(awk ' NR == '$i' { print $1 }' /tmp/ax25-config.tmp)
   if [ "$iface" != "" ] && [ "${iface:0:2}" == "nr" ] ; then
#      echo "select: $iface, iface: ${iface:0:2}"
      ifconfig "$iface" down
      echo " $iface down"
  fi
done

echo "Netrom Stopped"
exit 0

