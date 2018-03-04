#!/bin/bash
#
# kern_cpy_local.sh
#
# This script copies the components of a kernel to a local directory
# structure. It needs to be run from the base of the destination directory
#
# *** Run this script at the root directory of where you want to place
# the kernel components so that you don't hose your workstation.
#

# Debug flag to show what would be copied
#DRY_RUN="true"

BASE_DIR="$(pwd)/kern"
KERNEL=kernel7

# destination directory
BOOT_DIR="$BASE_DIR/boot"
FS_DIR="$BASE_DIR"

# kernel source tree for compass kernel
#SRC_DIR="/home/$(whoami)/dev/github/"
#SRC_LINUXDIR="$SRC_DIR/linux"

# kernel source tree for experimental raspian kernel
kernver="4.15.rc8"
# specify the modules directory
SRC_DIR="/home/kernel/raspi_linux"
# specify the kernel source tree
SRC_LINUXDIR="$SRC_DIR/raspi_$kernver"

# kernel source tree for
SRC_BOOTDIR="$SRC_LINUXDIR/arch/arm/boot"

# Don't run as root
if [[ $EUID -eq 0 ]]; then
  echo "*** Run as user not root" 2>&1
  exit 1
fi

if [ ! -d $BOOT_DIR ] ; then
   mkdir -p $BOOT_DIR/dts/overlays
   echo "Made directory $BOOT_DIR/dts/overlays"
fi

if [ ! -d "$FS_DIR/lib/modules" ] ; then
   mkdir -p "$FS_DIR/lib/modules"
   echo "Made directory $FS_DIR/lib/modules"
fi

pushd $SRC_LINUXDIR > /dev/null
kernel_version="$(make kernelversion)"
popd > /dev/null

echo $kernel_version > $BASE_DIR/version
echo "Copying files for kernel version $kernel_version"

#  refresh the modules
DEST_DIR="$FS_DIR/lib/modules"
if [ "$DRY_RUN" = "true" ] ; then
   echo "Copying $(ls -1 $SRC_DIR/lib/modules/* | wc -l) modules to: $DEST_DIR"
else
   rsync -au $SRC_DIR/lib/modules/* $DEST_DIR
   if [ $? -ne 0 ] ; then
      echo "Problem rsyncing modules: "
      exit 1
   fi
fi

# backup existing kernel file
SRC_FILE="$BOOT_DIR/$KERNEL.img"
DEST_FILE="$BOOT_DIR/$KERNEL-backup.img"
if [ -f "$SRC_FILE" ] ; then
   if [ "$DRY_RUN" = "true" ] ; then
      echo "Copying $(ls -1 $SRC_FILE | wc -l) backup kernel: $DEST_FILE"
   else
      cp  $SRC_FILE $DEST_FILE
      if [ $? -ne 0 ] ; then
         echo "Problem backing up file: $SRC_FILE"
         exit 1
      fi
   fi
fi

SRC_FILE="$SRC_BOOTDIR/zImage"
DEST_FILE="$BOOT_DIR/zImage"
if [ "$DRY_RUN" = "true" ] ; then
   echo "Copying $(ls -1 $SRC_FILE | wc -l) kernel file to: $DEST_FILE"
else
   cp $SRC_FILE $DEST_FILE
   if [ $? -ne 0 ] ; then
      echo "Problem copying file: $SRC_FILE"
   fi
fi

SRC_FILE="$SRC_BOOTDIR/dts/*.dtb"
DEST_DIR="$BOOT_DIR/dts"
if [ "$DRY_RUN" = "true" ] ; then
   echo "Copying $(ls -1 $SRC_FILE | wc -l) device tree binary files to: $DEST_DIR"
else
   rsync -a $SRC_FILE "$DEST_DIR"
   if [ $? -ne 0 ] ; then
      echo "Problem copying files: $SRC_FILE"
   fi
fi

SRC_FILE="$SRC_BOOTDIR/dts/overlays/*.dtb*"
DEST_DIR="$BOOT_DIR/dts/overlays/"
if [ "$DRY_RUN" = "true" ] ; then
   echo "Copying $(ls -1 $SRC_FILE | wc -l) device tree binary files to: $DEST_DIR"
else
   rsync -a $SRC_FILE "$DEST_DIR"
   if [ $? -ne 0 ] ; then
      echo "Problem copying file: $SRC_FILE"
   fi
fi

SRC_FILE="$SRC_BOOTDIR/dts/overlays/README"
DEST_DIR="$BOOT_DIR/dts/overlays/"
if [ "$DRY_RUN" = "true" ] ; then
   echo "Copying $(ls -1 $SRC_FILE | wc -l) overlay README file to: $DEST_DIR"
else
   rsync -au $SRC_FILE $DEST_DIR
fi

if [ "$DRY_RUN" != "true" ] ; then
   sync
   echo
   echo "==== directory of $BOOT_DIR"
   ls -salt $BOOT_DIR
   echo
   echo "==== directory of $BOOT_DIR/dts"
   ls -salt $BOOT_DIR/dts
   echo
   echo "==== directory of $BOOT_DIR/dts/overlays/udr*"
   ls -salt $BOOT_DIR/dts/overlays/udr*
   echo
   echo "==== directory of $FS_DIR"
   ls -salt $FS_DIR
fi

echo
echo "*** Finished copying kernel components to $BASE_DIR"
