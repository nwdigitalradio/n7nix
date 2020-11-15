#!/bin/sh
#
# This script stops then starts direwolf & all AX.25 systemd services
# Switched from bash to sh to run from at

USER=
QUIET=

# if DEBUG is defined then echo
dbgecho() { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# if QUIET is defined the DO NOT echo
quietecho() { if [ -z "$QUIET" ] ; then echo "$*"; fi }

# ===== function get_user
# When running as root need to find a valid local bin directory
# Set USER based on finding a REQUIRED_PROGRAM

get_user() {
   # Check if there is only a single user on this system
   if [ $(ls /home | wc -l) -eq 1 ] ; then
       USER=$(ls /home)
   else
       USER=
       # Get here when there is more than one user on this system,
       # Find the local bin that has the requested program
       # Requested program list: $LOCALBIN_LIST
       # Assume all programs from $LOCALBIN_LIST are in same directory path

       REQUIRED_PROGRAM="ax25-stop"

       for DIR in $(ls /home | tr '\n' ' ') ; do
          if [ -d "/home/$DIR" ] && [ -e "/home/$DIR/bin/$REQUIRED_PROGRAM" ] ; then
              USER="$DIR"
              dbgecho "DEBUG: found dir: /home/$DIR & /home/$DIR/bin/$REQUIRED_PROGRAM"

              break
          fi
        done
    fi
}

# ==== function check_user
# verify user name is legit

check_user() {
   userok=false
   dbgecho "$scriptname: Verify user name: $USER"
   for username in $USERLIST ; do
      if [ "$USER" = "$username" ] ; then
         userok=true;
      fi
   done

   if [ "$userok" = "false" ] ; then
      echo "$scriptname: User name ($USER) does not exist,  must be one of: $USERLIST"
      exit 1
   fi

   dbgecho "using USER: $USER"
}

# ===== main

# Check if there are any args on command line
# Use to quiet output
if [ $# != 0 ] ; then
   QUIET="-q"
fi

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

# Check if running as root
if [ $(id -u) != 0 ] ; then
    # NOT running as root
    USER=$(whoami)
else
    get_user
    check_user
fi

LOCAL_BIN_PATH="/home/$USER/bin"
sudo $LOCAL_BIN_PATH/ax25-stop $QUIET
sleep 1
sudo $LOCAL_BIN_PATH/ax25-start $QUIET
