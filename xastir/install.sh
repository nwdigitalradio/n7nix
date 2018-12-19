#!/bin/bash
#
# Install APRS app xastir
#
# Uncomment this statement for debug echos
# DEBUG=1
USER=

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function get_user

function get_user() {
   # Check if there is only a single user on this system
   if (( `ls /home | wc -l` == 1 )) ; then
      USER=$(ls /home)
   else
      echo "Enter user name ($(echo $USERLIST | tr '\n' ' ')), followed by [enter]:"
      read -e USER
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

#
# ===== main
#
# Check if there are any args on command line
if (( $# != 0 )) ; then
    USER="$1"
else
    echo "$scriptname: Must supply user name as command line argument"
    exit 1
fi
# Check for any arguments
if (( $# != 0 )) ; then
   USER="$1"
fi

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

# Check if user name was supplied on command line
if [ -z "$USER" ] ; then
    # prompt for call sign & user name
    # Check if there is only a single user on this system
    get_user
fi

# Verify user name
check_user

sudo apt-get install xastir

# Enable desktop icon for xastir
cp xastir.desktop /home/$USER/Desktop

# Copy silence.wav to xastir sound dir
sudo cp *.wav /usr/share/xastir/sounds

cd
git clone https://github.com/Xastir/xastir-sounds
cd xastir-sounds/sounds
sudo cp *.wav /usr/share/xastir/sounds

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: Xastir install script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
echo
