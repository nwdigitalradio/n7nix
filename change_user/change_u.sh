#!/bin/bash
#
# First as root `adduser <username>`
# Then as root run this script to set up groups and copy files from
# user pi
#
# Then edit /etc/lightdm/lightdm.conf
#  Change autologin-user=pi to new user
#
# This script will setup groups for a new user
# But also need to replace 'pi' with new user name in these files:
#  - /usr/bin/raspi-config
#  - /etc/lightdm/lightdm.conf
# now run sudo raspi-config
# Select the third option:
#   3 Enable Boot to Desktop/Scratch
# Select the second option:
#   2 Desktop Log in as user 'bob' at the graphical desktop
# Doing this allows configuration files to be written to automatically
# boot into the GUI with a changed user name (not pi)
#
# From Kenny, captured for reference
# If you edit /etc/dbus-1/system.d/bluetooth.conf
# Change the line:
#   <deny send_destination="org.bluez"/>
# to:
#  <allow send_destination="org.bluez"/>
# and reboot
#
# Uncomment this statement for debug echos
DEBUG=1
#
scriptname="`basename $0`"
GROUP_LIST="adm mail dialout cdrom sudo audio video plugdev games users input netdev gpio i2c spi usb"

USER=
GROUP=
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

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

# ===== main

# must be root
if [[ $EUID != 0 ]] ; then
   echo "Login as root"
   exit 1
fi

# check if group exists
echo "Checking if groups exist"
for GROUP in $GROUP_LIST ; do
   if [ $(getent group $GROUP) ]; then
     echo "group $GROUP exists."
   else
     echo "group $GROUP does not exist...adding"
     /usr/sbin/groupadd $GROUP
   fi
done

# Get new user name
get_user

# check if user is in group
echo "Checking if user is in groups"
for GROUP in $GROUP_LIST ; do
   if id -nG "$USER" | grep -qw "$GROUP"; then
      echo $USER belongs to $GROUP
   else
      echo $USER does not belong to group $GROUP
      usermod -a -G $GROUP $USER
   fi
done

rsync -av --ignore-existing /home/pi/* /home/$USER

chown -R $USER:$USER /home/$USER

echo "$scriptname done, may need to reboot $(hostname)"
