#!/bin/bash
#
# Uncomment this statement for debug echos
DEBUG=1

SBINPATH="/usr/local/sbin"
AX25_CFGDIR="/usr/local/etc/ax25"

ENABLE_NR="true"

#for debug only
CALLSIGN="N7NIX"
AX25PORT="udr0"
NR_SSID="6"
ALIAS="UROLPZ"

ROUTE_SSID="8"
ROUTE_ALIAS="UNLPZ"
# end debug

# How often to send Netrom updates in minutes
#  (Default is 60)
NETROMADVTIME=120

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

if [ "$ENABLE_NR" = "true" ]; then

   echo "Starting up Netrom"

   # Be sure we're running as root
   if [[ $EUID != 0 ]] ; then
      echo "Must be root"
      exit 1
   fi

   # Needs entries in ax25d.conf, /etc/ax25/nrports
   # Also needs nrattach & ifconfig

   grep -i "$CALLSIGN-$NR_SSID" $AX25_CFGDIR/nrports
   if [ $? -eq 1 ] ; then
      echo "No netrom ports defined in nrports"
      mv $AX25_CFGDIR/nrports $AX25_CFGDIR/nrports-dist
      echo "Original ax25 nrports saved as nrports-dist"
   {
echo "netrom  $CALLSIGN-$NR_SSID       $ALIAS   236     Net/ROM Switch Port"
   } >> $AX25_CFGDIR/nrports
   else
      echo "Netrom ports already config'ed"
   fi
   lsmod | grep -i "netrom"
   if [ $? -eq 0 ] ; then
      echo "Netrom loaded as module"
   else
      echo "No netrom module, check if compiled in kernel"
      grep -i netrom /proc/kallsyms > /dev/null 2>&1
      if [ $? -eq 0 ] ; then
         echo "Netrom enabled in kernel"
      else
         echo "=== Netrom is not enabled in kernel, loading module"
	 modprobe netrom
         if [ $? -eq 0 ] ; then
            echo "modprobe of Netrom failed"
	    exit 1
         fi
      fi
   fi
   netrom_dev=$(nrattach -i 44.24.197.66 -m 236 netrom)
   if [ $? -eq 0 ] ; then
      echo "debug: netrom_dev: $netrom_dev"
      netrom_dev="${netrom_dev##* }"
      echo "Netrom device is: $netrom_dev"
   else
      echo "netrom attach failed, exiting"
      exit 1
   fi
   ifconfig $netrom_dev 44.24.197.66 netmask 255.255.255.0
   if [ $? -eq 0 ] ; then
      echo "netrom interface $netrom_dev is configured"
   else
      echo "netrom interface $netrom_dev config FAILED"
      exit 1
   fi
else
   echo "Not starting up Netrom"
fi


grep -i "$AX25PORT" $AX25_CFGDIR/nrbroadcast
if [ $? -eq 1 ] ; then
   echo "nrbroadcast needs configuration"
   # Add a comment char to every line that does not have one
   sed -i '/^#/!s/^/# /g' $AX25_CFGDIR/nrbroadcast
# setup nrbroadcast file
# axport      min_obs def_qual       worst_qual     verbose
{
echo "$AX25PORT		5	192		100		0"
} >> $AX25_CFGDIR/nrbroadcast
else
   echo "netrom broadcast already config'ed"
fi

# Start up the netromd system as configured in /etc/ax25/nr*
# manages NET/ROM routing table & broadcasts
#  -i : send routes immediately
#  -l : enable logging
#  -t : send netrom updates every 60 min
#  -d : OPTIONAL: enable debugging statements
#
# is netromd already running?
pidof netromd > /dev/null
if [ $? -eq 0 ]; then
   echo "netrom daemon already running"
else
   echo "Starting netrom daemon"
   netromd -d -i -l -t $NETROMADVTIME
   if [ $? -eq 0 ] ; then
      echo "netrom daemon is configured"
   else
      echo "netrom daemon start FAILURE"
   fi
fi

if [ ! -z "$DEBUG" ] ; then
# Add local machine to route
$SBINPATH/nrparms -routes udr0 $CALLSIGN-$ROUTE_SSID + 120
$SBINPATH/nrparms -nodes $CALLSIGN-$ROUTE_SSID + "$ROUTE_ALIAS" 120 6 "udr0" $CALLSIGN-$ROUTE_SSID

if [ -f "/var/ax25/nrsave" ] ; then
   echo "Display nrsave"
   cat /var/ax25/nrsave
else
   echo "nrsave does not exist"
fi
fi

echo
echo "ax.25 install script FINISHED"
echo

exit 0

