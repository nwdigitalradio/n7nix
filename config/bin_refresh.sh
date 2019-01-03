#!/bin/bash
#
# Copy scripts to local bin directory
# Used to update the DRAWS image
#
# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"

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

# ===== function CopyBinFiles

function CopyBinFiles() {

# Check if directory exists.
if [ ! -d "$userbindir" ] ; then
   mkdir $userbindir
fi

cp /home/$USER/n7nix/systemd/bin/* $userbindir
cp /home/$USER/n7nix/bin/* $userbindir
cp /home/$USER/n7nix/iptables/iptable-*.sh $userbindir
sudo chown -R $USER:$USER $userbindir

echo
echo "FINISHED copying bin files"
}

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

get_user
check_user

userbindir=/home/$USER/bin
CopyBinFiles
cd $userbindir
