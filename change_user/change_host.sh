#!/bin/bash
#
# Change host machine name in these files:
# - /etc/hostname
# - /etc/mailname
# - /etc/hosts
DEBUG=

scriptname="`basename $0`"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function get_hostname
# Validate hostname
#   https://stackoverflow.com/questions/20763980/check-if-a-string-contains-only-specified-characters-including-underscores/20764037

function get_hostname() {

    #  Clear the read buffer
    read -t 1 -n 10000 discard

    read -ep "Enter new host name followed by [enter]: " HOSTNAME

    # From hostname(7) man page
    # Valid characters for hostnames are ASCII(7) letters from a to z,
    # the digits from 0 to 9, and the hyphen (-).
    # A hostname may not start with a hyphen.
    if [[ $HOSTNAME =~ ^[a-z0-9\-]+$ ]]; then
        dbgecho "str: $HOSTNAME  matches"
        return 0
    else
        dbgecho "str: $HOSTNAME does NOT match"
        return 1
    fi
}

# ===== main

# Be sure we're running as root
#if [[ $EUID != 0 ]] ; then
#   echo "Must be root"
#   exit 1
#fi

hostname_default="draws"
HOSTNAME=$(cat /etc/hostname | tail -1)

# Check hostname
echo " === Current hostname: $HOSTNAME"

# Change hostname

while  ! get_hostname ; do
    echo "Input error for $HOSTNAME, try again"
    echo "Valid characters for hostnames are:"
    echo " letters from a to z,"
    echo " the digits from 0 to 9,"
    echo " and the hyphen (-)"
done

if [ ! -z "$HOSTNAME" ] ; then
    echo "Setting new hostname: $HOSTNAME"
else
    echo "Setting hostname to default: $hostname_default"
    HOSTNAME="$hostname_default"
fi

#echo "$HOSTNAME" > /etc/hostname
echo "$HOSTNAME" | sudo tee /etc/hostname > /dev/null

echo "=== Set mail hostname"
echo "$HOSTNAME.localhost" | sudo tee /etc/mailname > /dev/null

# Be sure system host name can be resolved

grep "127.0.1.1" /etc/hosts
if [ $? -eq 0 ] ; then
   # Found 127.0.1.1 entry
   # Be sure hostnames match
   HOSTNAME_CHECK=$(grep "127.0.1.1" /etc/hosts | awk {'print $2'})
   if [ "$HOSTNAME" != "$HOSTNAME_CHECK" ] ; then
      echo "Make host names match between /etc/hostname & /etc/hosts"
      sudo sed -i -e "/127.0.1.1/ s/127.0.1.1\t.*/127.0.1.1\t$HOSTNAME ${HOSTNAME}.localnet/" /etc/hosts
   else
      echo "host names match between /etc/hostname & /etc/hosts"
   fi
else
   # Add a 127.0.1.1 entry to /etc/hosts
   sudo sed -i '1i\'"127.0.1.1\t$HOSTNAME $HOSTNAME.localnet" /etc/hosts
   if [ $? -ne 0 ] ; then
      echo "Failed to modify /etc/hosts file"
   fi
fi

# Get hostname to verify
#HOSTNAME=$(cat /etc/hostname | tail -1)

echo "FINISHED changing host name to: $HOSTNAME"
