#!/bin/bash
#
# Config claws-email for an imap server
# Edit these account setting variables
#
#  account_name=$USER@localhost
#  name=$REALNAME
#  address=$USER@$(hostname).localnet
#  user_id=$USER
#  signature_path=/home/$USER/.signature


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


# ===== main

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

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
   echo "USER=$USER not null"
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

echo "Enter real name ie. Joe Blow, followed by [enter]:"
read -e REALNAME

account_name=$USER@localhost
name=$REALNAME
address=$USER@$(hostname).localnet
user_id=$USER
signature_path=/home/$USER/.signature

