#!/bin/bash
#
# Configure axports & ax25d.conf files
#
# Uncomment this statement for debug echos
DEBUG=1

CALLSIGN="N0NE"
AX25PORT="udr0"
SSID="15"
AX25DSSID="0"
AX25_CFGDIR="/usr/local/etc/ax25"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function prompt_read

function prompt_read() {
echo "Enter call sign, followed by [enter]:"
read CALLSIGN

sizecallstr=${#CALLSIGN}

if (( sizecallstr > 6 )) || ((sizecallstr < 3 )) ; then
   echo "Invalid call sign: $CALLSIGN, length = $sizecallstr"
   exit 1
fi

CALLSIGN=$(echo "$CALLSIGN" | tr '[a-z]' '[A-Z]')
dbgecho "Using CALL SIGN: $CALLSIGN"

echo "Enter ssid for direwolf APRS, followed by [enter]:"
read SSID

sizessidstr=${#SSID}

if (( sizessidstr > 2 )) || ((sizessidstr < 0 )) ; then
   echo "Invalid ssid: $SSID, length = $sizessidstr"
   exit 1
fi

dbgecho "Using SSID: $SSID"

}

# ===== main

if [ ! -f "/etc/ax25/axports" ] && [ ! -f "$AX25_CFGDIR/axports" ] ; then
   echo "Need to install libax25, tools & apps"
   exit 1
fi

# check if both /etc/ax25 and /usr/local/etc/ directories exist
if [ ! -d "/etc/ax25" ] || [ ! -L /etc/ax25 ] ; then
   if [ ! -d "/usr/local/etc/ax25" ] ; then
      echo "ax25 directory /usr/local/etc/ax25 DOES NOT exist, install ax25 first"
      exit
   else
      echo "Making symbolic link to /etc/ax25"
      ln -s /usr/local/etc/ax25 /etc/ax25
   fi
else
   echo " Found ax.25 link or directory"
fi

# make sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root to modify /etc files"
   exit 1
fi

grep -i "udr0" $AX25_CFGDIR/axports
if [ $? -eq 1 ] ; then
   echo "No ax25 ports defined"
   mv $AX25_CFGDIR/axports $AX25_CFGDIR/axports-dist
   echo "Original ax25ports saved as axports-dist"

   prompt_read
{
echo "# $AX25_CFGDIR/axports"
echo "#"
echo "# The format of this file is:"
echo "#portname	callsign	speed	paclen	window	description"
echo "$AX25PORT            $CALLSIGN-$SSID         9600    255     2       Direwolf port"
} >> $AX25_CFGDIR/axports
else
   echo "AX.25 port $AX25PORT already configured"
fi

# Set up a listening socket, for testing
# Make it different than previous SSID
if ((SSID < 15)) ; then
   AX25DSSID=$((SSID+1))
else
   AX25DSSID=$((SSID-1))
fi

grep  "N0ONE" /etc/ax25/ax25d.conf >/dev/null
if [ $? -eq 0 ] ; then
   echo "ax25d not configured"
   mv $AX25_CFGDIR/ax25d.conf $AX25_CFGDIR/ax25d.conf-dist
   echo "Original ax25d.conf saved as ax25d.conf-dist"
   # copy first 16 lines of file
   sed -n '1,16p' $AX25_CFGDIR/ax25d.conf-dist >> $AX25_CFGDIR/ax25d.conf

{
echo "[$CALLSIGN-$AX25DSSID VIA $AX25PORT]"
echo "NOCALL   * * * * * *  L"
echo "default  * * * * * *  - root /usr/sbin/ttylinkd ttylinkd"
} >> $AX25_CFGDIR/ax25d.conf

else
   echo "ax25d.conf already configured"
fi

echo "ax.25 config complete"

