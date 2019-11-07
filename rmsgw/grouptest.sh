#!/bin/bash
#
#
# Does rmsgw group exist?
GROUP="rmsgw"

# ===== main

# must be root
if [[ $EUID != 0 ]] ; then
   echo "Run as root"
   exit 1
fi


if [ $(getent group $GROUP) ]; then
    echo "group $GROUP exists."
else
    echo "group $GROUP does not exist...adding"
     /usr/sbin/groupadd $GROUP
    usermod -a -G rmsgw rmsgw
fi

# This also works
#grep -q -E "^$GROUP:" /etc/group
#if [ $? -ne 0 ] ; then
    ## rmsgw group does not exist
    #group add rmsgw
    #usermod -a -G rmsgw rmsgw
#fi

DIR="/usr/local/etc/rmsgw"
echo "Change owner:group of directory: $DIR"
chown -R rmsgw:rmsgw $DIR
