#!/bin/bash
#
# Run this after copying a fresh compass file system image
#
# Uncomment this statement for debug echos
DEBUG=1

UPDDATE_NOW=false

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== main

# make sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root"
   exit 1
fi

if [ "$UPDATE_NOW" = "true" ] ; then
  apt-get update
  apt-get upgrade
  apt-get install -y mg jed rsync build-essential autoconf automake libtool git libasound2-dev whois
fi

# is there even a user pi?
ls /home | grep pi > /dev/null 2>&1
if [ $? -eq 0 ] ; then
   echo "User pi found"
   echo "Determine if default password is being used"

   # get salt
   SALT=$(grep -i pi /etc/shadow | awk -F\$ '{print $3}')

   PASSGEN=$(mkpasswd --method=sha-512 --salt=$SALT raspberry)
   PASSFILE=$(grep -i pi /etc/shadow | cut -d ':' -f2)

#   dbgecho "SALT: $SALT"
#   dbgecho "pass file: $PASSFILE"
#   dbgecho "pass  gen: $PASSGEN"

   if [ "$PASSFILE" = "$PASSGEN" ] ; then
      echo "Need to change your password for user pi NOW"
      exit 1
   fi

else
   echo "User pi NOT found"
fi

# Change hostname
# mg /etc/hosts
# mg /etc/hostname

HOSTNAME=$(cat /etc/hostname)
dbgecho "Hostname: $HOSTNAME"

DATETZ=$(date +%Z)
dbgecho "TIme zone: $DATETZ"

# dpkg-reconfigure tzdata

exit 0
