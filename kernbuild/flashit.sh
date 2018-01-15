#/bin/bash
flash_dev="/dev/sde"

img_date="2018-01-11"

if mount | grep -q $flash_dev; then
   echo "$flash_dev is mounted, need to unmount"
   exit
fi

time dd if=${img_date}-compass.img of=/dev/sde bs=1M status=progress

mount /dev/sde1 /mnt/fat32
touch /mnt/fat32/ssh
sync
umount /mnt/fat32
echo
echo "Finished flashing part"
