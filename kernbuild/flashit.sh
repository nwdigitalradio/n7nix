#/bin/bash
#
# flashit.sh
# - Unzips & writes to flash a compass image file
#
# No command line args used
# Set up 3 variables before using this script
# - flash_dev flash device
# - img_date  image date (defaults to todays date)
# - kernlite  true or false for including window manager
#
# If DEBUG is defined no flash writing will occur
DEBUG=1

img_date=
flash_dev="/dev/sde"
kernlite="true"

# must run as root
if [ -z $DEBUG ] && [[ $EUID -ne 0 ]]; then
  echo "*** Run as root" 2>&1
  exit 1
fi

# Create flash file name
if [ -z "$img_date" ] ; then
   img_date="$(date "+%Y-%m-%d")"
fi

flashfile_name="${img_date}-compass"

# Is lite or full image required
if [ "$kernlite" == "true" ] ; then
   flashfile_name="${img_date}-compass-lite"
fi

# Does the image file already exist?
if [ ! -f ${flashfile_name}.img ] ; then
   # Does the zipped image file already exist?
   if [ -f "image_${flashfile_name}.zip" ] ; then
      echo "Unzipping file: image_${flashfile_name}.zip ... please wait"
      unzip image_${flashfile_name}.zip
   else
      # Download the request compass image file
      echo "Downloading compass image file: image_${flashfile_name}.zip ... please wait"
      wget -qt 3 https://nwdr-compass-images.s3.amazonaws.com/image_${flashfile_name}.zip
      if [ $? -ne 0 ] ; then
         echo "Problem encountered downloading compass image file: image_${flashfile_name}.zip"
         exit 1
      fi
      echo "Unzipping file: image_${flashfile_name}.zip"
      unzip image_${flashfile_name}.zip
   fi
fi

if mount | grep -q $flash_dev; then
   echo "$flash_dev is mounted ... unmounting"
   umount ${flash_dev}1
   umount ${flash_dev}2
fi

echo "Copying image file: ${flashfile_name}.img, size: $(du -h ${flashfile_name}.img | cut -f1)"

if [ ! -z $DEBUG ] ; then
  echo "Exiting on DEBUG"
  exit
fi

time dd if=${flashfile_name}.img of=$flash_dev bs=1M status=progress

mount ${flash_dev}1 /mnt/fat32
touch /mnt/fat32/ssh
sync
umount /mnt/fat32
echo
echo "Finished flashing part"
