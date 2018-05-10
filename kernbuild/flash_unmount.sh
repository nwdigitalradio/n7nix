#!/bin/bash

flash_dev="/dev/sde"

flash_device=${flash_dev}1
mntpnt=$(findmnt -n $flash_device | cut -d ' ' -f1)
if [ ! -z "$mntpnt" ] ; then
   echo "$flash_device is mounted at $mntpnt ... unmounting"
   umount $mntpnt
fi

flash_device=${flash_dev}2
mntpnt=$(findmnt -n $flash_device | cut -d ' ' -f1)
if [ ! -z "$mntpnt" ] ; then
   echo "$flash_device is mounted at $mntpnt ... unmounting"
   umount $mntpnt
fi

echo "Finished unmounting flash part"