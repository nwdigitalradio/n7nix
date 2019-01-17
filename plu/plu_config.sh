#!/bin/bash
#
# Configure a previously installed paclink-unix
# Also configures mutt & postfix
#
# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

CALLSIGN="N0ONE"
SRC_DIR="/usr/local/src"
PLU_CFG_FILE="/usr/local/etc/wl2k.conf"
POSTFIX_CFG_FILE="/etc/postfix/transport"
PLU_VAR_DIR="/usr/local/var/wl2k"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function get_callsign

function get_callsign() {

    # Check if call sign var has already been set
    if [ "$CALLSIGN" == "N0ONE" ] ; then
        echo "Enter call sign, followed by [enter]:"
        read -e CALLSIGN
    fi
    # Validate callsign
    sizecallstr=${#CALLSIGN}

    if (( sizecallstr > 6 )) || ((sizecallstr < 3 )) ; then
        echo "Invalid call sign: $CALLSIGN, length = $sizecallstr"
        exit 1
    fi

    # Convert callsign to upper case
    CALLSIGN=$(echo "$CALLSIGN" | tr '[a-z]' '[A-Z]')

    dbgecho "Using CALL SIGN: $CALLSIGN"
}

# ===== function get_user

function get_user() {
# prompt for user name
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
}

# ===== function files_exist()
function files_exist() {
   retcode=1

   for filename in `echo ${CFG_FILES}` ; do
      if [ ! -f "$filename" ] ; then
         retcode=0
      else
         echo "File check found: $filename"
      fi
   done
   return $retcode
}

# ===== main

echo
echo "=== paclink-unix config START"

# make sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root"
   exit 1
fi

# Save current directory
CUR_DIR=$(pwd)

# if there are any args on command line assume it's a callsign
if (( $# != 0 )) ; then
   CALLSIGN="$1"
fi

# if there are any args on command line assume it's
# user name & callsign
if (( $# != 0 )) ; then
   USER="$1"
   if (( $# == 2 )) ; then
      CALLSIGN="$2"
   fi
else
   get_user
fi

if [ -z "$USER" ] ; then
   echo "USER string is null, get_user"
   get_user
else
   echo "USER=$USER, OK"
fi

# verify user name is legit
check_user

if [ $user != $USER ] ; then
   echo "Please login as $USER"
   exit 1
fi

MUTT_CFG_FILE="/home/$USER/.muttrc"
CFG_FILES="$PLU_CFG_FILE $MUTT_CFG_FILE $POSTFIX_CFG_FILE"

# Have paclink-unix, mutt & postfix already been installed?
files_exist
if [ $? -eq 1 ] ; then
   echo "paclink-unix, mutt & postfix already installed ..."
   exit 0
fi

echo "=== configuring paclink-unix"

# set permissions for /usr/local/var/wl2k directory
# Check user name
# get_user previously set $USER
chown -R $USER:mail $PLU_VAR_DIR

# Add user to group mail
if id -nG "$USER" | grep -qw mail; then
    echo "$USER already belongs to group mail"
else
    echo "Adding $USER to group mail"
    usermod -a -G mail $USER
fi

# Check for a valid callsign
get_callsign

# Determine if paclink-unix has already been configured
grep $CALLSIGN $PLU_CFG_FILE
if [ $? -ne 0 ] ; then

   # Edit /usr/local/etc/wl2k.conf file
   # sed -i  save result to input file

   # Set mycall=
   sed -i -e "/mycall=/ s/mycall=.*/mycall=$CALLSIGN/" $PLU_CFG_FILE

   ## Set email=user_name@localhost

   sed -i -e "s/^#email=.*/email=$USER@localhost/" $PLU_CFG_FILE

   # Set wl2k-password=
   echo "Enter Winlink password, followed by [enter]:"
   read -e PASSWD
   sed -i -e "s/^#wl2k-password=/wl2k-password=$PASSWD/" $PLU_CFG_FILE

   # Set ax25port=
   # Assume axports was set by a previous configuration script
   # get first arg in last line
   PORT=$(tail -1 /etc/ax25/axports | cut -d ' ' -f 1)
   sed -i -e "s/^#ax25port=/ax25port=$PORT/" $PLU_CFG_FILE

else
   echo "$scriptname: paclink-unix has already been configured."
fi

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: paclink-unix basic config FINISHED" | tee -a $UDR_INSTALL_LOGFILE
echo
# configure postfix
source $CUR_DIR/postfix_config.sh $USER
# configure mutt
source $CUR_DIR/../email/mutt/mutt_config.sh $USER $CALLSIGN
