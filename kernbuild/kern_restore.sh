#!/bin/bash
#
# kern_restore.sh
#
# Restore kernel components to active boot directories
#  - use kern_backup.sh to create backup directory
#  - check version file for kernel version being restored.
#
# Debug flag to show what would be copied
#DRY_RUN="true"

# Where files will be copied from
BASE_DIR="$(pwd)/kern_bup"
KERNEL=kernel7

# Need to run as root
if [[ $EUID -ne 0 ]]; then
  echo "*** Run as root" 2>&1
  exit 1
fi

if [ "$DRY_RUN" = "true" ] ; then
   echo "*** Dry run only, no files copied"
   echo
fi

echo "Check source directories"
if [ ! -d $BASE_DIR ] ; then
   echo "Source directory $BASE_DIR not found"
   exit
fi
kernel_version=$(tr -d '\0' < $BASE_DIR/version)
echo "Restoring files for kernel version $kernel_version"

#  restore the modules
echo "Copying modules"
SRC_DIR="$BASE_DIR/lib/modules"
DEST_DIR="/lib/modules"
if [ "$DRY_RUN" = "true" ] ; then
   echo "Copying $(ls -1 $SRC_DIR/* | wc -l) modules to: $DEST_DIR"
else
   rsync -au $SRC_DIR/* $DEST_DIR
   if [ $? -ne 0 ] ; then
      echo "Problem rsyncing modules: "
      exit 1
   fi
fi

# backup existing kernel file
SRC_FILE="/boot/$KERNEL.img"
DEST_FILE="/boot/$KERNEL-backup.img"
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

# restore the kernel file
echo "Copying kernel"
SRC_FILE="$BASE_DIR/boot/$KERNEL.img"
DEST_FILE="/boot/$KERNEL.img"
if [ "$DRY_RUN" = "true" ] ; then
   echo "Copying $(ls -1 $SRC_FILE | wc -l) kernel: $DEST_FILE"
else
   cp  $SRC_FILE $DEST_FILE
   if [ $? -ne 0 ] ; then
      echo "Problem backing up file: $SRC_FILE"
      exit 1
   fi
fi

# restore dtb files
echo "Copying dtb files"
SRC_FILE="$BASE_DIR/boot/*.dtb"
DEST_DIR="/boot"
if [ "$DRY_RUN" = "true" ] ; then
   echo "Copying $(ls -1 $SRC_FILE | wc -l) dtb files: $DEST_DIR"
else
   # NEVER do this
   # get rid of existing dtb files
   # rm "$DEST_DIR/*.dtb"

   cp  $SRC_FILE $DEST_DIR
   if [ $? -ne 0 ] ; then
      echo "Problem backing up file: $SRC_FILE"
      exit 1
   fi
fi

# restore overlays
echo "Copying overlay files"
SRC_DIR="$BASE_DIR/boot/overlays"
DEST_DIR="/boot/overlays"
if [ "$DRY_RUN" = "true" ] ; then
   echo "Copying $(ls -1 $SRC_FILE | wc -l) device tree overlay files to: $DEST_DIR"
else
   rsync -a $SRC_DIR/* "$DEST_DIR"
   if [ $? -ne 0 ] ; then
      echo "Problem copying files: $SRC_FILE"
   fi
fi

if [ "$DRY_RUN" != "true" ] ; then
   sync
   echo
   echo "==== directory of /lib/modules"
   ls -salt /lib/modules
   echo
   echo "==== directory of /boot"
   ls -salt /boot
fi

echo
echo "*** Finished restoring kernel components from $BASE_DIR"
