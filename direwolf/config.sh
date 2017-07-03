#!/bin/bash
#
# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

USER=pi
CALLSIGN="N0ONE"
CALLSIGN0="$CALLSIGN-1"
CALLSIGN1="$CALLSIGN-2"

DIREWOLF_CFGFILE="/etc/direwolf.conf"
firmware_prodfile="/sys/firmware/devicetree/base/hat/product"
firmware_prod_idfile="/sys/firmware/devicetree/base/hat/product_id"
firmware_vendorfile="/sys/firmware/devicetree/base/hat/vendor"

PROD_ID_NAMES=("INVALID" "INVALID" "UDRC" "UDRC II" "1WSpot")
NWDIG_VENDOR_NAME="NW Digital Radio"

# Default to udrc II for gpio assignment
chan1ptt_gpio=12
chan2ptt_gpio=23

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

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

# ===== function EEPROM id_check
# Return code:
# 0 = no EEPROM or no device tree found
# 1 = HAT found but not a UDRC
# 2 = UDRC
# 3 = UDRC II
# 4 = 1WSpot

function id_check() {
# Initialize to EEPROM not found
udrc_prod_id=0
dbgecho "Starting udrc id check"

# Does firmware file exist
if [ -f $firmware_prodfile ] ; then
   # Read product file
   UDRC_PROD="$(cat $firmware_prodfile)"
   # Read product file
   FIRM_VENDOR="$(cat $firmware_vendorfile)"
   # Read product id file
   UDRC_ID="$(cat $firmware_prod_idfile)"
   #get last character in product id file
   UDRC_ID=${UDRC_ID: -1}

   dbgecho "UDRC_PROD: $UDRC_PROD, ID: $UDRC_ID"

   if [[ "$FIRM_VENDOR" == "$NWDIG_VENDOR_NAME" ]] ; then
      case $UDRC_PROD in
         "Universal Digital Radio Controller")
            udrc_prod_id=2
         ;;
         "Universal Digital Radio Controller II")
            udrc_prod_id=3
         ;;
         "1WSpot")
            udrc_prod_id=4
         ;;
         *)
            echo "Found something but not a UDRC: $UDRC_PROD"
            udrc_prod_id=1
         ;;
      esac
   else

      dbgecho "Probably not a NW Digital Radio product: $FIRM_VENDOR"
      udrc_prod_id=1
   fi

   if [ udrc_prod_id != 0 ] && [ udrc_prod_id != 1 ] ; then
      if (( UDRC_ID == udrc_prod_id )) ; then
         dbgecho "Product ID match: $udrc_prod_id"
      else
         echo "Product ID MISMATCH $UDRC_ID : $udrc_prod_id"
         udrc_prod_id=1
      fi
   fi
   dbgecho "Found HAT for ${PROD_ID_NAMES[$UDRC_ID]} with product ID: $UDRC_ID"
else
   # RPi HAT ID EEPROM may not have been programmed in engineering samples
   # or there is no RPi HAT installed.
   udrc_prod_id=0
fi

dbgecho "Finished udrc id check"
return $udrc_prod_id
}

# ===== main

echo
echo "direwolf config START"

# Be sure we're running as root
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
if [ ! -e "/etc/$filename" ] ; then
   # Check for a Debian package install
   if [ -e "/usr/share/doc/direwolf/examples/direwolf.conf.gz" ] ; then
      echo "Coping /usr/share/doc/direwolf/examples/direwolf.conf*"
      cp /usr/share/doc/direwolf/examples/direwolf.conf* /etc
      pushd /etc
      gunzip direwolf.conf.gz
      popd > /dev/null
   else
      # Check for a source install to users home dir
      if [ -e "/home/$USER/$filename" ] ; then
         echo "Coping /home/$USER/$filename"
         cp /home/$USER/$filename /etc
      # Check for a source install by root
      elif [ -e "/root/$filename" ] ; then
         echo "Coping /root/$filename"
         cp /root/$filename /etc
      else
         echo "$scriptname: $filename not found in /home/$USER, /root or /usr/share/doc/direwolf/examples/"
         exit 1
      fi
   fi
else
   echo "Found an existing /etc/$filename config file."
fi

# Check which UDRC product is found
id_check
id_check_ret="$?"

case $id_check_ret in
0|1)
   echo "No UDRC found, exiting"
   exit 1
;;
2)
   echo "Original UDRC is installed."
   chan2ptt_gpio=12
;;
3)
   echo "UDRC II installed"
   chan2ptt_gpio=23
;;
4)
   echo "One Watt Spot installed"
   chan1ptt_gpio=-23
;;
*)
   echo "Invalid udrc id ... exiting"
   exit 1
;;
esac

# Verify alsa enumerates udrc sound card

CARDNO=$(aplay -l | grep -i udrc)

if [ ! -z "$CARDNO" ] ; then
   echo "udrc card number line: $CARDNO"
   CARDNO=$(echo $CARDNO | cut -d ' ' -f2 | cut -d':' -f1)
   echo "udrc is sound card #$CARDNO"
else
   echo "No udrc sound card found by aplay ... exiting"
   exit 1
fi

dbgecho "MYCALL"
sed -i -e "/MYCALL N0CALL/ s/N0CALL/$CALLSIGN0/" $DIREWOLF_CFGFILE
dbgecho "ADEVICE"
#sed -i -e '/ADEVICE  plughw/ s/# ADEVICE  plughw:1,0/ADEVICE plughw:1,0 plughw:1,0/' $DIREWOLF_CFGFILE
sed -i -e '/ADEVICE  plughw/ s/# ADEVICE  plughw:1,0/ADEVICE plughw:CARD=udrc,DEV=0 plughw:CARD=udrc,DEV=0/' $DIREWOLF_CFGFILE
dbgecho "ACHANNELS"
sed -i -e '/ACHANNELS 1/ s/1/2/' $DIREWOLF_CFGFILE
dbgecho "PTT"
sed -i -e '/#PTT GPIO 25/ s/#PTT GPIO 25/PTT GPIO 12/' $DIREWOLF_CFGFILE
# Set up the second channel
dbgecho "CHANNEL1"
sed -i -e "/#CHANNEL 1/ s/#CHANNEL 1/CHANNEL 1\nPTT GPIO 23\nMODEM 1200\nMYCALL $CALLSIGN1\n/" $DIREWOLF_CFGFILE

echo "Config Internet Gateway LOGIN"

# Igates need a code so they can log into the tier 2 servers.
# It is based on your callsign, and there is a utility called
# callpass in Xastir that will compute it.

type -P ./callpass &>/dev/null
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

# Changed per Doug Kingston's suggestion
sed -i -e "/^[#]*IGLOGIN / s/^[#]*IGLOGIN .*/IGLOGIN $CALLSIGN $logincode\n/" $DIREWOLF_CFGFILE
dbgecho "IGSERVER"
sed -i -e "/#IGSERVER / s/^#//" $DIREWOLF_CFGFILE

echo "$(date "+%Y %m %d %T %Z"): direwolf config script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "direwolf config script FINISHED"
echo
