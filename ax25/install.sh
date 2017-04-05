#!/bin/bash
#
# Configure axports & ax25d.conf files
#
# Uncomment this statement for debug echos
DEBUG=1

CALLSIGN="N0ONE"
AX25PORT="udr0"
SSID="15"
AX25DSSID="0"
AX25_CFGDIR="/usr/local/etc/ax25"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function get_callsign

function get_callsign() {

# Check if call sign var has already been set
if [ "$CALLSIGN" == "N0ONE" ] ; then

   read -t 1 -n 10000 discard
   echo "Enter call sign, followed by [enter]:"
   read CALLSIGN

   sizecallstr=${#CALLSIGN}

   if (( sizecallstr > 6 )) || ((sizecallstr < 3 )) ; then
      echo "Invalid call sign: $CALLSIGN, length = $sizecallstr"
      return 0
   fi

   # Convert callsign to upper case
   CALLSIGN=$(echo "$CALLSIGN" | tr '[a-z]' '[A-Z]')
fi

dbgecho "Using CALL SIGN: $CALLSIGN"
return 1
}

# ===== function get_ssid

function get_ssid() {

read -t 1 -n 10000 discard
echo "Enter ssid (0 - 15) for direwolf APRS, followed by [enter]:"
read -e SSID

if [ -z "${SSID##*[!0-9]*}" ] ; then
   echo "Input: $SSID, not a positive integer"
   return 0
fi

sizessidstr=${#SSID}

if (( sizessidstr > 2 )) || ((sizessidstr < 0 )) ; then
   echo "Invalid ssid: $SSID, length = $sizessidstr, should be 1 or 2 numbers"
   return 0
fi

dbgecho "Using SSID: $SSID"
return 1
}

# ===== function prompt_read

function prompt_read() {
while get_callsign ; do
  echo "Input error, try again"
done

while get_ssid ; do
  echo "Input error, try again"
done
}

# ===== main

echo
echo "AX.25 config START"

if [ ! -f "/etc/ax25/axports" ] && [ ! -f "$AX25_CFGDIR/axports" ] ; then
   echo "Need to install libax25, tools & apps"
   exit 1
fi

# check if /etc/ax25 exists as a directory or symbolic link
if [ ! -d "/etc/ax25" ] || [ ! -L "/etc/ax25" ] ; then
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

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root to modify /etc files"
   exit 1
fi

# if there are any args on command line assume it's a callsign
if (( $# != 0 )) ; then
   CALLSIGN="$1"
fi

# Check for a valid callsign
get_callsign

grep -i "$AX25PORT" $AX25_CFGDIR/axports
if [ $? -eq 1 ] ; then
   echo "No ax25 ports defined"
   mv $AX25_CFGDIR/axports $AX25_CFGDIR/axports-dist
   echo "Original ax25 axports saved as axports-dist"

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

UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
echo "$(date "+%Y %m %d %T %Z"): ax.25 install script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "ax.25 install script FINISHED"
echo

