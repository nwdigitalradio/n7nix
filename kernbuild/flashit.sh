#!/bin/bash
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
#DEBUG=1

flash_dev="/dev/sde"

# Build image name from these variables
# Need this for raspbian
img_date="2018-04-18"
kernlite="true"

# Choose one for compass or raspbian
#fs_source="compass"
fs_source="raspbian-stretch"

# must run as root
if [ -z $DEBUG ] && [[ $EUID -ne 0 ]]; then
  echo "*** Run as root" 2>&1
  exit 1
fi

# Used by Compass, since it has daily builds
# Create flash file name
if [ -z "$img_date" ] ; then
   img_date="$(date "+%Y-%m-%d")"
fi

# Is lite or full image required
   flashfile_name="${img_date}-${fs_source}"
if [ "$kernlite" == "true" ] ; then
   flashfile_name="${img_date}-${fs_source}-lite"
fi

zipfile_name="${flashfile_name}.zip"
if [ "${fs_source:0:7}" == "compass" ] ; then
   zipfile_name="image_${flashfile_name}.zip"
fi

echo "Using base filename: $flashfile_name, zip filename: $zipfile_name"

# Does the image file already exist?
if [ ! -f "${flashfile_name}.img" ] ; then
   # Does the zipped image file already exist?
    if [ -f "${zipfile_name}" ] ; then
      echo "Unzipping file: ${zipfile_name} ... please wait"
      unzip ${zipfile_name}
   else
      # Download the requested image file
      if [ "${fs_source:0:7}" == "compass" ] ; then
         # Download a compass image
         echo "Downloading compass image file: ${zipfile_name} ... please wait"
         wget -qt 3 https://nwdr-compass-images.s3.amazonaws.com/${zipfile_name}
      else
         #Download a raspbian image
         echo "Downloading raspbian image file: ${zipfile_name} ... please wait"\
         raspbianfile_name="raspbian_latest"
         if [ "$kernlite" == "true" ] ; then
            raspbianfile_name="raspbian_lite_latest"
         fi
         wget -qt 3 https://downloads.raspberrypi.org/${raspbianfile_name}
      fi
      # Check status of download
      if [ $? -ne 0 ] ; then
         echo "Problem encountered downloading image file: ${zipfile_name}"
         exit 1
      fi
      echo "Unzipping file: ${zipfile_name}"
      unzip ${zipfile_name}
   fi
else
   echo "Flash image file: ${flashfile_name}.img exists, using it"
fi

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

echo "Copying image file: ${flashfile_name}.img, size: $(du -h ${flashfile_name}.img | cut -f1)"

if [ ! -z $DEBUG ] ; then
  echo "Exiting on DEBUG"
  exit
fi

time dd if=${flashfile_name}.img of=$flash_dev bs=1M status=progress
sync

mount ${flash_dev}1 /mnt/fat32
touch /mnt/fat32/ssh
sync
umount /mnt/fat32
echo
echo "Finished flashing part"
