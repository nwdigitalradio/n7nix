#!/bin/bash
#
SERVICELIST="hostapd dnsmasq"

echo "Test if $SERVICELIST services have been started."
for service_name in `echo ${SERVICELIST}` ; do
echo
echo "== status $service_name services =="
   systemctl is-active $service_name >/dev/null
   if [ "$?" = "0" ] ; then
      echo "$service_name is running"
   else
      echo "$service_name is NOT running"
   fi
   systemctl status $service_name
done
