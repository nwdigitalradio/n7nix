#!/bin/bash
#
# postfix_reset.sh
#
# Get rid of current configuration files for dovecot & postfix &
# re-configure.
#
# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"
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

# Be sure we ARE root
if [[ $EUID != 0 ]] ; then
   echo "Must run as root"
   exit 1
fi

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

get_user
check_user

# Get updated configuration scripts
cd /home/$USER/n7nix
sudo -u $USER git pull

# get rid of your existing configuration, need to be root
echo "Removing packages dovecot-core postfix"
apt-get remove -y --purge dovecot-core postfix

# get fresh configuration files
echo "Installing packages dovecot-core dovecot-imapd postfix"
apt-get install -y dovecot-core dovecot-imapd postfix

# Configure new configuration files

cd plu

# Configure postfix
./postfix_config.sh

cd /home/$USER/n7nix/email/claws
# Configure dovecot
./dovecot_config.sh

# No configure claws-mail using these instructions
# https://github.com/nwdigitalradio/n7nix/blob/master/email/claws/README.md

# Verify postfix configuration
# must not be root

# cd /home/$USER/n7nix/debug
# sudo -u $USER ./chk_mail.sh

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: script FINISHED"
