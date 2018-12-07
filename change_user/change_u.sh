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
#    - autologin-user=
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
function new_user() {

echo "Enter user name followed by [enter]:"
read -e USER

# Check if user name already exists

USERLIST="$(ls /home)"
USERCNT=$(ls -1 /home | wc -l)
USERLIST="$(echo $USERLIST | tr '\n' ' ')"
user_exists=false

for username in $USERLIST ; do
    if [ "$USER" = "$username" ] ; then
        user_exists=true
    fi
done

if [ "$user_exists" = "false" ] ; then
    adduser $USER
else
    echo "User $USER already exists"
    exit 1
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

# must be root
if [[ $EUID != 0 ]] ; then
   echo "Login as root"
   exit 1
fi

# Check for any arguments
if (( $# != 0 )) ; then
   USER="$1"
fi

USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

# Check if user name was supplied on command line
if [ -z "$USER" ] ; then
    # prompt for call sign & user name
    # Check if there is only a single user on this system
    new_user
fi
# Verify user name
check_user

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

# In file /etc/lightdm/lightdm.conf set autologin-user
#  ie. change autologin user to something other than pi
#  Search for line beginning autologin-user=
sed -i -e "/autologin-user=/ s/^autologin-user=.*/autologin-user=$USER/" /etc/lightdm/lightdm.conf

echo "$scriptname done, may need to reboot $(hostname)"
