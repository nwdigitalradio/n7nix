#!/bin/bash
#
# kern_cpy_flash.sh
#
# This script copies the components of a kernel to appropriate
# directories on a mounted SD card.
#
# *** You MUST make sure that the variable flash_dev is set
# properly or you could hose your workstation.
#
# This script should be run from the base directory where kernel
# components were copied. If running from a git clone you can run it in
# the same directory it was cloned to. The requirement is that
# there should be a `kern` directory with all the kernel components in
# it.

flash_dev=sde
FULL_UPDATE=true
KERNEL=kernel7

BOOT_DIR=/mnt/fat32
FS_DIR=/mnt/ext4

# For reference only
# Run from Linux kernel base address
#SRC_DIR=/home/gunn/dev/github
#SRC_BOOTDIR="arch/arm/boot"

# Run from local directory created by kern_cpy_local.sh
SRC_DIR="$(pwd)/kern"
SRC_BOOTDIR="$SRC_DIR/boot"

# must run as root
if [[ $EUID -ne 0 ]]; then
  echo "*** Run as root" 2>&1
  exit 1
fi

# Check for required source directory
if [ ! -d $SRC_DIR ] ; then
   echo "Directory: $SRC_DIR does not exist."
   echo "Need to run kern_cpy_local.sh first."
   exit 1
fi

# Verify mount points exist
if [ ! -d $BOOT_DIR ] ; then
   mkdir -p $BOOT_DIR
fi

if [ ! -d $FS_DIR ] ; then
   mkdir -p $FS_DIR
fi

# Verify flash target devices exist
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

# back-up existing kernel image to $KERNEL-n.img
SRC_FILE="$BOOT_DIR/$KERNEL.img"
n=
kernfile=$KERNEL.img
while [ -f "$BOOT_DIR/$kernfile" ] ; do
  n=$(( ${n:=0} + 1 ))
  kernfile=$KERNEL-$n.img
done
cp  $SRC_FILE $BOOT_DIR/$kernfile
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

# copy dtb files to boot_dir
SRC_FILE="$SRC_BOOTDIR/dts/*.dtb"
rsync -au --exclude=".*" $SRC_FILE $BOOT_DIR
if [ $? -ne 0 ] ; then
   echo "Problem copying file: $SRC_FILE"
fi

# copy overlay files to boot_dir/overlays
SRC_FILE="$SRC_BOOTDIR/dts/overlays/*.dtb*"
rsync -au --exclude=".*" $SRC_FILE $BOOT_DIR/overlays/
if [ $? -ne 0 ] ; then
   echo "Problem copying file: $SRC_FILE"
fi

rsync -au $SRC_BOOTDIR/dts/overlays/README $BOOT_DIR/overlays/

echo
echo "==== syncing writes to partitions"
sync

echo
echo "==== directory of $BOOT_DIR"
ls -salt $BOOT_DIR

echo
echo "==== directory of $FS_DIR"
ls -salt $FS_DIR

echo
echo "==== unmounting partitions $BOOT_DIR & $FS_DIR"
umount $BOOT_DIR
umount $FS_DIR

echo
echo "*** Finished copying updated kernel to flash"
