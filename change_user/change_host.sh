#!/bin/bash
#
# Change host machine name in these files:
# - /etc/hostname
# - /etc/mailname
# - /etc/hosts

scriptname="`basename $0`"

# Check hostname
echo " === Verify hostname"
HOSTNAME=$(cat /etc/hostname | tail -1)
echo "$scriptname: Current hostname: $HOSTNAME"


   # Change hostname
   echo "Using host name: $HOSTNAME, change it"
   echo "Enter new host name followed by [enter]:"
   read -t 1 -n 10000 discard
   read -e HOSTNAME
   echo "$HOSTNAME" > /etc/hostname


# Get hostname again to replicate it in the othe files
HOSTNAME=$(cat /etc/hostname | tail -1)

echo "=== Set mail hostname"
echo "$HOSTNAME.localhost" > /etc/mailname

# Be sure system host name can be resolved

grep "127.0.1.1" /etc/hosts
if [ $? -eq 0 ] ; then
   # Found 127.0.1.1 entry
   # Be sure hostnames match
   HOSTNAME_CHECK=$(grep "127.0.1.1" /etc/hosts | awk {'print $2'})
   if [ "$HOSTNAME" != "$HOSTNAME_CHECK" ] ; then
      echo "Make host names match between /etc/hostname & /etc/hosts"
      sed -i -e "/127.0.1.1/ s/127.0.1.1\t.*/127.0.1.1\t$HOSTNAME ${HOSTNAME}.localnet/" /etc/hosts
   else
      echo "host names match between /etc/hostname & /etc/hosts"
   fi
else
   # Add a 127.0.1.1 entry to /etc/hosts
   sed -i '1i\'"127.0.1.1\t$HOSTNAME $HOSTNAME.localnet" /etc/hosts
   if [ $? -ne 0 ] ; then
      echo "Failed to modify /etc/hosts file"
   fi
fi

echo "FINISHED changing host names"