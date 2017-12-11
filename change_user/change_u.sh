#!/bin/bash
#
# Setup groups for a new user
#
# Uncomment this statement for debug echos
DEBUG=1
#
scriptname="`basename $0`"
GROUP_LIST="adm mail dialout cdrom sudo audio video plugdev games users input netdev gpio i2c spi usb"

USER=
GROUP=

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

# check if group exists

for GROUP in $GROUP_LIST ; do
   if [ $(getent group $GROUP) ]; then
     echo "group $GROUP exists."
   else
     echo "group $GROUP does not exist...adding"
     /usr/sbin/groupadd $GROUP
   fi
done


# check if user is in group
for GROUP in $GROUP_LIST ; do
   if id -nG "$USER" | grep -qw "$GROUP"; then
      echo $USER belongs to $GROUP
   else
      echo $USER does not belong to group $GROUP
      usermod -a -G $GROUP $USER
   fi
done

echo "$scriptname done, may need to reboot $(hostname)"
