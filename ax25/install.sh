#!/bin/bash
#
# Uncomment this statement for debug echos
DEBUG=1

CALLSIGN="N0NE"
SSID="4"
AX25PORT="udr0"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

if [ ! -f "/etc/ax25/axports" ] ; then
   echo "Need to install libax25, tools & apps"
   exit 1
fi

# make sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root to modify /etc files"
   exit 1
fi

grep -i "udr0" /etc/ax25/axports
if [ $? -eq 1 ] ; then
   echo "No ax25 ports defined"
{
echo "$AX25PORT            $CALLSIGN-$SSID         9600    255     2       APRS"
} >> /etc/ax25/axports
else
  echo "AX.25 port $AX25PORT already configured"
fi

exit 0
