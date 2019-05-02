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
which $prgram
if [ "$?" -eq 0 ] ; then
   dbgecho "Found $prgram in path"
   $prgram
   PROD_ID=$?
else
   currentdir=$(pwd)
   # Get path one level down
   pathdn1=$( echo ${currentdir%/*})
   dbgecho "Test pwd: $currentdir, path: $pathdn1"
   if [ -e "$pathdn1/bin/$prgram" ] ; then
       dbgecho "Found $prgram here: $pathdn1/bin"
       $pathdn1/bin/$prgram -
       PROD_ID=$?
   else
       echo "Could not locate $prgram default product ID to draws"
       PROD_ID=4
   fi
fi
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

filename="direwolf.conf"
# Check if direwolf config file exists in /root
# Remove confusion, this file is NOT to be used ast the direwolf config file.

if [ -e "/root/$filename" ] ; then
   mv /root/$filename /root/direwolf.conf.dist
fi

# Check if direwolf config file exists in /etc

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
get_prod_id

case $PROD_ID in
0|1)
   echo "$(tput setaf 1)No udrc sound card found default to DRAWS$(tput setaf 7) "
   # left channel
   chan1ptt_gpio=12
   # right channel
   chan2ptt_gpio=23
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
   echo "Draws installed"
   # left channel
   chan1ptt_gpio=12
   # right channel
   chan2ptt_gpio=23
;;
5)
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
   echo "$(tput setaf 1)No udrc sound card found by aplay ... $(tput setaf 7) "
   # Used to exit here BUT there is no way to rerun core config.
fi

dbgecho "MYCALL"
sed -i -e "/MYCALL N0CALL/ s/N0CALL/$CALLSIGN0/" $DIREWOLF_CFGFILE
dbgecho "ADEVICE"
#sed -i -e '/ADEVICE  plughw/ s/# ADEVICE  plughw:1,0/ADEVICE plughw:1,0 plughw:1,0/' $DIREWOLF_CFGFILE
sed -i -e '/ADEVICE  plughw/ s/# ADEVICE  plughw:1,0/ADEVICE plughw:CARD=udrc,DEV=0 plughw:CARD=udrc,DEV=0/' $DIREWOLF_CFGFILE
dbgecho "ACHANNELS"
sed -i -e '/ACHANNELS 1/ s/1/2/' $DIREWOLF_CFGFILE
dbgecho "PTT"
sed -i -e "/#PTT GPIO 25/ s/#PTT GPIO 25/PTT GPIO $chan1ptt_gpio/" $DIREWOLF_CFGFILE
# Set up the second channel
dbgecho "CHANNEL1"
sed -i -e "/#CHANNEL 1/ s/#CHANNEL 1/CHANNEL 1\nPTT GPIO $chan2ptt_gpio\nMODEM 1200\nMYCALL $CALLSIGN1\n/" $DIREWOLF_CFGFILE

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

echo "$(date "+%Y %m %d %T %Z"): $scriptname: direwolf config script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "direwolf config script FINISHED"
echo
