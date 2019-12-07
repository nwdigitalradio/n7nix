#!/bin/bash
#
# Configure axports & ax25d.conf files
#
# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

CALLSIGN="N0ONE"
USER=
AX25PORT="udr"
SSID="15"
AX25_CFGDIR="/usr/local/etc/ax25"

PRIMARY_DEVICE="udr0"
ALTERNATE_DEVICE="udr1"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function get product id of HAT

# Set PROD_ID:
# 0 = no EEPROM or no device tree found
# 1 = HAT found but not a UDRC
# 2 = UDRC
# 3 = UDRC II
# 4 = DRAWS
# 5 = 1WSpot

function get_prod_id() {
# Initialize product ID
PROD_ID=
prgram="udrcver.sh"

which $prgram > /dev/null 2>&1
if [ "$?" -eq 0 ] ; then
   dbgecho "Found $prgram in path"
   $prgram -
   PROD_ID=$?
else
   currentdir=$(pwd)
   # Get path one level down
   pathdn1=$( echo ${currentdir%/*})
   dbgecho "Test pwd: $currentdir, path: $pathdn1"
   if [ -e "$pathdn1/bin/$prgram" ] ; then
       dbgecho "Found $prgram here: $pathdn1/bin"
       $pathdn1/bin/$prgram -1
       PROD_ID=$?
   else
       echo "Could not locate $prgram default product ID to draws"
       PROD_ID=4
   fi
fi
}

# ===== function get_callsign

function get_callsign() {

# Check if call sign var has already been set
if [ "$CALLSIGN" == "N0ONE" ] ; then

   read -t 1 -n 10000 discard
   echo -n "Enter call sign, followed by [enter]"
   read -ep ": " CALLSIGN

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

# ===== function get_user

function get_user() {
   # Check if there is only a single user on this system
   if (( `ls /home | wc -l` == 1 )) ; then
      USER=$(ls /home)
   else
      echo -n "Enter user name ($(echo $USERLIST | tr '\n' ' ')), followed by [enter]"
      read -ep ": " USER
   fi
}

# ==== function check_user
# verify user name is legit

function check_user() {
   userok=false
   dbgecho "$scriptname: Verify user name: $USER"
   for username in $USERLIST ; do
      if [ "$USER" = "$username" ] ; then
         userok=true;
      fi
   done

   if [ "$userok" = "false" ] ; then
      echo "User name ($USER) does not exist,  must be one of: $USERLIST"
      exit 1
   fi

   dbgecho "using USER: $USER"
}


# ===== function get_ssid

function get_ssid() {

read -t 1 -n 10000 discard
echo -n "Enter ssid (0 - 15) for direwolf APRS, followed by [enter]"
read -ep ": " SSID

# Remove any leading zeros
SSID=$((10#$SSID))

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

# ===== function cfg_axports
function cfg_axports() {

   # Prompt for call sign & SSID
   prompt_read
   # udrc II has 2 ports
{
echo "# $AX25_CFGDIR/axports"
echo "#"
echo "# The format of this file is:"
echo "#portname	callsign	speed	paclen	window	description"
echo "${PRIMARY_DEVICE}        $CALLSIGN-10            9600    255     2       Winlink port"
echo "${ALTERNATE_DEVICE}        $CALLSIGN-$SSID             9600    255     2       Direwolf port"
} > $AX25_CFGDIR/axports

}

# ===== main

echo
echo "AX.25 config START"

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root to modify /etc files"
   exit 1
fi

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

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

# Expecting command line arguments: ./config.sh USER_NAME CALLSIGN

case $# in
    0)
        get_callsign
        get_user
    ;;
    1)
        USER="$1"
        get_callsign
    ;;
    2)
        USER="$1"
        CALLSIGN="$2"
    ;;
    *)
       echo -e "\n$(tput setaf 4) Expecting only 2 arguments on command line(tput setaf 7)\n"
    ;;
esac

echo "AX.25 config: User=$USER, Callsign=$CALLSIGN"

# Check for a valid callsign
get_callsign

# Check for a valid user name
check_user

# Get product ID of hat
get_prod_id
echo "HAT product id: $PROD_ID"

# Test product ID for UDRC or UDRC II
if [[ "$PROD_ID" -eq 2 ]] || [[ "$PROD_ID" -eq 3 ]] ; then
    # UDRC or UDRC II hat
    PRIMARY_DEVICE="udr1"
    ALTERNATE_DEVICE="udr0"
elif [ "$PROD_ID" -eq 4 ] ; then
    # Draws hat
    PRIMARY_DEVICE="udr0"
    ALTERNATE_DEVICE="udr1"
else
    echo "Product ID test failed with: $PROD_ID"
fi

# Setup ax.25 axports file
numports=$(grep -c "$AX25PORT" $AX25_CFGDIR/axports)
if [ $? -ne 2 ] ; then
   if (( $numports == 0 )) ; then
      echo "No ax25 ports defined"
      mv $AX25_CFGDIR/axports $AX25_CFGDIR/axports-dist
      echo "Original ax25 axports saved as axports-dist"
      cfg_axports
   else
      echo "AX.25 $AX25PORT already configured with $numports ports"
   fi
else
   echo "AX.25 ports file $AX25_CFGDIR/axports doesn't exist ... creating."
   cfg_axports
fi

grep  "N0ONE" /etc/ax25/ax25d.conf >/dev/null
if [ $? -eq 0 ] ; then
   echo "ax25d not configured"
   mv $AX25_CFGDIR/ax25d.conf $AX25_CFGDIR/ax25d.conf-dist
   echo "Original ax25d.conf saved as ax25d.conf-dist"
   # copy first 16 lines of file
   sed -n '1,16p' $AX25_CFGDIR/ax25d.conf-dist > $AX25_CFGDIR/ax25d.conf

{
echo "[$CALLSIGN-10 VIA ${PRIMARY_DEVICE}]"
echo "NOCALL   * * * * * *  L"
echo "default  * * * * * *  - rmsgw /usr/local/bin/rmsgw rmsgw -P %d %U"
echo "#"
echo "[$CALLSIGN VIA ${PRIMARY_DEVICE}]"
echo "NOCALL   * * * * * *  L"
echo "default  * * * * * *  - $USER /usr/local/bin/wl2kax25d wl2kax25d -c %U -a %d"
} >> $AX25_CFGDIR/ax25d.conf

else
   echo "ax25d.conf already configured"
fi

echo "$(date "+%Y %m %d %T %Z"): $scriptname: AX.25 config script FINISHED" | tee -a $UDR_INSTALL_LOGFILE
echo

