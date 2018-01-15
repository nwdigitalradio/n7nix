#/bin/bash

flash_dev="/dev/sde"
img_date="2018-01-11"

# must run as root
if [[ $EUID -ne 0 ]]; then
  echo "*** Run as root" 2>&1
  exit 1
fi

if mount | grep -q $flash_dev; then
   echo "$flash_dev is mounted ... unmounting"
   umount ${flash_dev}1
   umount ${flash_dev}2
fi

time dd if=${img_date}-compass.img of=$flash_dev bs=1M status=progress

mount ${flash_dev}1 /mnt/fat32
touch /mnt/fat32/ssh
sync
umount /mnt/fat32
echo
echo "Finished flashing part"
