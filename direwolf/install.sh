#!/bin/bash
#
# Uncomment this statement for debug echos
DEBUG=1

myname="`basename $0`"
USER=pi
CALLSIGN="N0ONE"
CALLSIGN0="$CALLSIGN-1"
CALLSIGN1="$CALLSIGN-2"
UDRCII=false
DIREWOLF_CFGFILE="/etc/direwolf.conf"
firmware_prodfile="/sys/firmware/devicetree/base/hat/product"
firmware_prod_idfile="/sys/firmware/devicetree/base/hat/product_id"

# Default to udrc II for gpio assignment
chan1ptt_gpio=12
chan2ptt_gpio=23

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed")
}

# ===== function get_callsign

function get_callsign() {

if [ "$CALLSIGN" == "N0ONE" ] ; then
   echo "Enter call sign, followed by [enter]:"
   read -e CALLSIGN

   sizecallstr=${#CALLSIGN}

   if (( sizecallstr > 6 )) || ((sizecallstr < 3 )) ; then
      echo "Invalid call sign: $CALLSIGN, length = $sizecallstr"
      exit 1
   fi

   # Convert callsign to upper case
   CALLSIGN=$(echo "$CALLSIGN" | tr '[a-z]' '[A-Z]')
fi

dbgecho "Using CALL SIGN: $CALLSIGN"
}

# ===== function udrc id_check

function id_check() {
# Initialize to EEPROM not found
udrc_prod_id=0
dbgecho "Starting udrc id check"

# Does firmware file exist
if [ -f $firmware_prodfile ] ; then
   # Read product file
   UDRC_PROD="$(cat $firmware_prodfile)"
   sizeprodstr=${#UDRC_PROD}
   dbgecho "UDRC_PROD: $UDRC_PROD, size: $sizeprodstr"
   if (( $sizeprodstr < 34 )) ; then
      dbgecho "Probably not a Universal Digital Radio Controller: $UDRC_PROD"
      udrc_prod_id=1
   elif [ "${UDRC_PROD:0:34}" == "Universal Digital Radio Controller" ] ; then
      dbgecho "Definitely some kind of UDRC"
   else
      echo "Found something but not a UDRC: $UDRC_PROD"
      udrc_prod_id=1
   fi

   # get last 2 characters in product file
   UDRC_PROD=${UDRC_PROD: -2}
   # Read product id file
   UDRC_ID="$(cat $firmware_prod_idfile)"
   #get last character in product id file
   UDRC_ID=${UDRC_ID: -1}
   udrc_prod_id=$UDRC_ID

   dbgecho "Product: $UDRC_PROD, Id: $UDRC_ID"
   if [ "$UDRC_PROD" == "II" ] && [ "$UDRC_ID" == "3" ] ; then
      dbgecho "Found a UDRC II"
      chan2ptt_gpio=23
      UDRCII=true
   elif [ "$UDRC_PROD" == "er" ] && [ "$UDRC_ID" == "2" ] ; then
      dbgecho "Found an original UDRC"
      chan2ptt_gpio=12
   else
      dbgecho "No UDRC found"
      udrc_prod_id=1
   fi

else
   # RPi HAT ID EEPROM may not have been programmed in engineering samples
   # or there is no RPi HAT installed.
   udrc_prod_id=0
fi

return $udrc_prod_id
}

# ===== main

echo
echo "direwolf config START"

# make sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root."
   exit 1
fi

# if there are any args on command line assume it's a callsign
if (( $# != 0 )) ; then
   CALLSIGN="$1"
fi

# Check for a valid callsign
get_callsign
CALLSIGN0="$CALLSIGN-1"
CALLSIGN1="$CALLSIGN-2"

# prompt for call sign & user name
# Check if there is only a single user on this system

USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

if (( `ls /home | wc -l` == 1 )) ; then
   USER=$(ls /home)
else
  echo "Enter user name ($(echo $USERLIST | tr '\n' ' ')), followed by [enter]:"
  read -e USER
fi

# verify user name is legit
userok=false

for username in $USERLIST ; do
  if [ "$USER" = "$username" ] ; then
     userok=true;
  fi
done

if [ "$userok" = "false" ] ; then
   echo "User name does not exist,  must be one of: $USERLIST"
   exit 1
fi

dbgecho "using USER: $USER"

# Check if direwolf config file exists in /etc
filename="direwolf.conf"
if [ ! -f "/etc/$filename" ] ; then
   if [ -f "/home/$USER/$filename" ] ; then
      echo "Coping /home/$USER/$filename"
      cp /home/$USER/$filename /etc
   elif [ -f "/root/$filename" ] ; then
      echo "Coping /root/$filename"
      cp /root/$filename /etc
   else
      echo "$filename not found in /home/$USER or /root"
      exit 1
   fi
else
   echo "Found /etc/$filename config file."
fi

# Check which UDRC product is found
id_check
id_check_ret="$?"

case $id_check_ret in
1)
   echo "No UDRC found, exiting"
   exit 1
;;
2)
   echo "Original UDRC is installed."
;;
3)
   echo "UDRC II installed"
;;
*)
   echo "Invalid udrc id ... exiting"
   exit 1
;;
esac

dbgecho "MYCALL"
sed -i -e "/MYCALL N0CALL/ s/N0CALL/$CALLSIGN0/" $DIREWOLF_CFGFILE
dbgecho "ADEVICE"
sed -i -e '/ADEVICE  plughw/ s/# ADEVICE  plughw:1,0/ADEVICE plughw:1,0 plughw:1,0/' $DIREWOLF_CFGFILE
dbgecho "ACHANNELS"
sed -i -e '/ACHANNELS 1/ s/1/2/' $DIREWOLF_CFGFILE
dbgecho "PTT"
sed -i -e '/#PTT GPIO 25/ s/#PTT GPIO 25/PTT GPIO 12/' $DIREWOLF_CFGFILE
# Set up the second channel
dbgecho "CHANNEL1"
sed -i -e "/#CHANNEL 1/ s/#CHANNEL 1/CHANNEL 1\nPTT GPIO 23\nMODEM 1200\nMYCALL $CALLSIGN1\n/" $DIREWOLF_CFGFILE

echo "Config ILOGIN"

# Igates need a code so they can log into the tier 2 servers.
# It is based on your callsign, and there is a utility called
# callpass in Xastir that will compute it.

type -P callpass &>/dev/null
if [ $? -ne 0 ] ; then
   echo "Building callpass"
   gcc -o callpass callpass.c

   # Check that callpass build was successful
   type -P ./callpass &>/dev/null
   if [ $? -ne 0 ] ; then
      echo
      echo "FAILED to build callpass"
      echo
  fi
fi

logincode=$(./callpass $CALLSIGN)
# Get last argument in string
logincode="${logincode##* }"
echo "Login code for $CALLSIGN for APRS tier 2 servers: $logincode"

sed -i -e "/#IGLOGIN / s/#IGLOGIN .*/IGLOGIN $CALLSIGN $logincode\n/" $DIREWOLF_CFGFILE
dbgecho "IGSERVER"
sed -i -e "/#IGSERVER / s/^#//" $DIREWOLF_CFGFILE

UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
echo "$(date "+%Y %m %d %T %Z"): direwolf config script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "direwolf config script FINISHED"
echo