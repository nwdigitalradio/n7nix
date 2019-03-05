#!/bin/bash
#
# Install all packages & programs required for:
#  direwolf, packet RMS Gateway, paclink-unix
#

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
imapinstall="false"
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

# ===== main

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "$scriptname: Must be root"
   exit 1
fi

echo "$(date "+%Y %m %d %T %Z"): $scriptname: image install script START" >> $UDR_INSTALL_LOGFILE
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
    source ./pluimap_install.sh
# This is both an install & configuration script
#    pushd ../email/claws/
#    source ./claws_install.sh
#    popd > /dev/null
else
    echo "$scriptname: Install basic paclink-unix"
    source ./plu_install.sh
fi
popd > /dev/null

pushd ../bbs
echo "$scriptname: Install fbb BBS"
sudo -u "$USER" ./install.sh $USER
popd > /dev/null

pushd ../xastir
echo "$scriptname: Install Xastir"
sudo -u "$USER" ./install.sh $USER
popd > /dev/null

pushd ../yaac
echo "$scriptname: Install YAAC"
sudo -u "$USER" ./install.sh $USER
popd > /dev/null

pushd ../hfprogs
echo "$scriptname: Install HF programs"
sudo -u "$USER" ./hf_install.sh $USER
popd > /dev/null

pushd ../dstar
echo "$scriptname: Install DStar programs"
sudo -u "$USER" ./install.sh $USER
popd > /dev/null

pushd ../ardop
echo "$scriptname: Install ardop programs"
./install.sh
popd > /dev/null

sudo apt-get -y install lm-sensors
apt-get -y purge libreoffice* minecraft-pi scratch scratch2 fluid geany smartsim python3-thonny sense-hat sense-emu-tools python-sense-emu python3-sense-emu idle-python*
apt-get clean
apt-get -y autoremove

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: image install script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
echo
