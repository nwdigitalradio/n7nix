#!/bin/bash
#
# kern_cpy_flash.sh
#
# This script copies the components of a kernel, to appropriate
# directories on a mounted SD card or a local directory.
#
# *** When coping to a mounted SD card you MUST make sure that the
# variable flash_dev is set properly or you could hose your workstation.
#
# This script should be run from the base directory where kernel was
# built.

flash_dev=sde
FULL_UPDATE=true
KERNEL=kernel7

BOOT_DIR=/mnt/fat32
FS_DIR=/mnt/ext4

# For reference only
# Run from Linux kernel base address
#SRC_DIR=/home/gunn/dev/github
#SRC_BOOTDIR="arch/arm/boot"

# Run from git repo
SRC_DIR="$(pwd)/kern"
SRC_BOOTDIR="$SRC_DIR/boot"

# must run as root
if [[ $EUID -ne 0 ]]; then
  echo "*** Run as root" 2>&1
  exit 1
fi

if [ ! -d $BOOT_DIR ] ; then
   mkdir -p $BOOT_DIR
fi

if [ ! -d $FS_DIR ] ; then
   mkdir -p $FS_DIR
fi

if [ ! -e "/dev/${flash_dev}1" ] ; then
   echo "Flash device: ${flash_dev}1 does not exist, exiting"
   exit 1
fi

if [ ! -e "/dev/${flash_dev}2" ] ; then
   echo "Flash device: ${flash_dev}2 does not exist, exiting"
   exit 1
fi

mount /dev/${flash_dev}1 $BOOT_DIR
if [ $? -ne 0 ] ; then
   echo "Mount failed on: /dev/${flash_dev}1"
   exit 1
fi
mount /dev/${flash_dev}2 $FS_DIR
if [ $? -ne 0 ] ; then
   echo "Mount failed on: /dev/${flash_dev}2"
   exit 1
fi

# Depending on what's been worked on usually do not have to
#  refresh the modules after each kernel build.
if [ "$FULL_UPDATE" == "true" ] ; then
   rsync -au $SRC_DIR/lib/modules/* $FS_DIR/lib/modules
   if [ $? -ne 0 ] ; then
      echo "Problem rsyncing modules dir"
      exit 1
   fi
fi

# back-up existing kernel image
SRC_FILE="$BOOT_DIR/$KERNEL.img"
cp  $SRC_FILE $BOOT_DIR/$KERNEL-backup.img
if [ $? -ne 0 ] ; then
   echo "Problem backing up file: $SRC_FILE"
   exit 1
fi

# copy a new kernel image
SRC_FILE="$SRC_BOOTDIR/zImage"
cp $SRC_FILE $BOOT_DIR/$KERNEL.img
if [ $? -ne 0 ] ; then
   echo "Problem copying file: $SRC_FILE"
fi

SRC_FILE="$SRC_BOOTDIR/dts/*.dtb"
rsync -au --exclude=".*" $SRC_FILE $BOOT_DIR
if [ $? -ne 0 ] ; then
   echo "Problem copying file: $SRC_FILE"
fi

SRC_FILE="$SRC_BOOTDIR/dts/overlays/*.dtb*"
rsync -au --exclude=".*" $SRC_FILE $BOOT_DIR/overlays/
if [ $? -ne 0 ] ; then
   echo "Problem copying file: $SRC_FILE"
fi

rsync -au $SRC_BOOTDIR/dts/overlays/README $BOOT_DIR/overlays/

sync

echo
echo "==== directory of $BOOT_DIR"
ls -salt $BOOT_DIR
echo
echo "==== directory of $FS_DIR"
ls -salt $FS_DIR
echo
umount $BOOT_DIR
umount $FS_DIR

echo
echo "*** Finished copying updated kernel to flash"
