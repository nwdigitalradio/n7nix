#!/bin/bash
#
# Install all packages & programs required for:
#  direwolf, packet RMS Gateway, paclink-unix
#

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
imapinstall="true"
USER=

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

# ===== function swap_size_check
# If swap too small, change config file /etc/dphys-swapfile & exit to
# do a reboot.
#
# To increase swap file size in /etc/dphys-swapfile:
# Default   CONF_SWAPSIZE=100    102396 KBytes
# Change to CONF_SWAPSIZE=1000  1023996 KBytes

function swap_size_check() {
    # Verify that swap size is large enough
    swap_size=$(swapon -s | tail -n1 | expand -t 1 | tr -s '[[:space:]] ' | cut -d' ' -f3)
    # Test if swap size is less than 1 Gig
    if (( swap_size < 1023996 )) ; then
        swap_config=$(grep -i conf_swapsize /etc/dphys-swapfile | cut -d"=" -f2)
        sudo sed -i -e "/CONF_SWAPSIZE/ s/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=1024/" /etc/dphys-swapfile

        echo "$(tput setaf 4)Swap size too small for source builds, changed from $swap_config to 1024 in config file"
        echo " Restarting dphys-swapfile process.$(tput setaf 7)"
        systemctl restart dphys-swapfile
        # Verify swap file size change
        swap_size=$(swapon -s | tail -n1 | expand -t 1 | tr -s '[[:space:]] ' | cut -d' ' -f3)
        echo "Swap file size verification: $swap_size"
    fi
}

# ===== main

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "$scriptname: Must be root"
   exit 1
fi

swap_size_check

echo "$(date "+%Y %m %d %T %Z"): $scriptname: image install script for packet ONLY START" | tee -a $UDR_INSTALL_LOGFILE
echo

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

echo "$scriptname: Install direwolf & ax25 files"
./core_install.sh

# run RMSGW install script as user other than root
pushd ../rmsgw
echo "$scriptname: Install RMS Gateway"
sudo -u "$USER" ./install.sh $USER
popd > /dev/null

# run IPTABLES install script as user other than root
pushd ../iptables
echo "$scriptname: Install iptables"
sudo -u "$USER" ./iptable_install.sh $USER
popd > /dev/null

pushd ../plu
if [ "$imapinstall" = "true" ] ; then
    echo "$scriptname: Install paclink-unix with imap"
    source ./plu_install.sh
# This is both an install & configuration script
#    pushd ../email/claws/
#    source ./claws_install.sh
#    popd > /dev/null
else
    echo "$scriptname: Install basic paclink-unix"
    source ./plu_install.sh
fi
popd > /dev/null

echo "$scriptname: Install sensor support"
sudo apt-get -y install lm-sensors

pushd ../config
echo "$scriptname: Install DRAWS sensor config file"

sudo -u "$USER" ./sensor_update.sh
popd > /dev/null

apt-get -y purge libreoffice* minecraft-pi scratch scratch2 fluid geany smartsim python3-thonny sense-hat sense-emu-tools python-sense-emu python3-sense-emu idle-python*
apt-get clean
apt-get -y autoremove

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: image install script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
echo
