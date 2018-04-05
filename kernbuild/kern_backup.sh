#!/bin/bash
#
# kern_backup.sh
#
# Copy all kernel components to another directory
#
# Debug flag to show what would be copied
#DRY_RUN="true"

# Where files will be copied to
BASE_DIR="$(pwd)/kern_bup"
KERNEL=kernel7

# Don't need to run as root
if [[ $EUID -eq 0 ]]; then
  echo "*** Run as user not root" 2>&1
  exit 1
fi

if [ "$DRY_RUN" = "true" ] ; then
   echo "*** Dry run only, no files copied"
   echo
fi

kernel_version=$(uname -r)
echo "Copying files for kernel version $kernel_version"

echo "Making destination directories"
if [ ! -d $BASE_DIR ] ; then
   mkdir -p $BASE_DIR/boot/overlays
   mkdir -p $BASE_DIR/lib/modules
   echo "Made destination directory $BASE_DIR"
fi

echo $kernel_version > $BASE_DIR/version

#  backup the modules
echo "Copying modules"
DEST_DIR="$BASE_DIR/lib/modules"
SRC_DIR="/lib/modules"
if [ "$DRY_RUN" = "true" ] ; then
   echo "Copying $(ls -1 $SRC_DIR/* | wc -l) modules to: $DEST_DIR"
else
   rsync -au $SRC_DIR/* $DEST_DIR
   if [ $? -ne 0 ] ; then
      echo "Problem rsyncing modules: "
      exit 1
   fi
fi

# backup the kernel
echo "Copying kernel"
SRC_FILE="/boot/$KERNEL.img"
DEST_FILE="$BASE_DIR/boot"
if [ "$DRY_RUN" = "true" ] ; then
   echo "Copying $(ls -1 $SRC_FILE | wc -l) backup kernel: $DEST_FILE"
else
   cp  $SRC_FILE $DEST_FILE
   if [ $? -ne 0 ] ; then
      echo "Problem backing up file: $SRC_FILE"
      exit 1
   fi
fi

# backup bin files
echo "Copying bin files"
SRC_FILE="/boot/*.bin"
DEST_FILE="$BASE_DIR/boot"
if [ "$DRY_RUN" = "true" ] ; then
   echo "Copying $(ls -1 $SRC_FILE | wc -l) backup bin files: $DEST_FILE"
else
   cp  $SRC_FILE $DEST_FILE
   if [ $? -ne 0 ] ; then
      echo "Problem backing up file: $SRC_FILE"
      exit 1
   fi
fi


# backup config files
echo "Copying config files"
SRC_FILE="/boot/*.txt"
DEST_FILE="$BASE_DIR/boot"
if [ "$DRY_RUN" = "true" ] ; then
   echo "Copying $(ls -1 $SRC_FILE | wc -l) backup config files: $DEST_FILE"
else
   cp  $SRC_FILE $DEST_FILE
   if [ $? -ne 0 ] ; then
      echo "Problem backing up file: $SRC_FILE"
      exit 1
   fi
fi

# back-up dtb files
echo "Copying dtb files"
SRC_FILE="/boot/*.dtb"
DEST_FILE="$BASE_DIR/boot"
if [ "$DRY_RUN" = "true" ] ; then
   echo "Copying $(ls -1 $SRC_FILE | wc -l) dtb files: $DEST_FILE"
else
   cp  $SRC_FILE $DEST_FILE
   if [ $? -ne 0 ] ; then
      echo "Problem backing up file: $SRC_FILE"
      exit 1
   fi
fi

# back-up overlays
echo "Copying overlay files"
SRC_FILE="/boot/overlays"
DEST_DIR="$BASE_DIR/boot/overlays"
if [ "$DRY_RUN" = "true" ] ; then
   echo "Copying $(ls -1 $SRC_FILE | wc -l) device tree overlay files to: $DEST_DIR"
else
   rsync -a $SRC_FILE/* "$DEST_DIR"
   if [ $? -ne 0 ] ; then
      echo "Problem copying files: $SRC_FILE"
   fi
fi

if [ "$DRY_RUN" != "true" ] ; then
   sync
   echo
   echo "==== directory of $BASE_DIR/lib/modules"
   ls -salt $BASE_DIR/lib/modules
   echo
   echo "==== directory of $BASE_DIR/boot"
   ls -salt $BASE_DIR/boot
fi

echo
echo "*** Finished backing up kernel components to $BASE_DIR"
