#!/bin/bash
#
# kern_cpy_remote.sh
#
# Copy kernel components to remote machine
# Need to be able to login as root on remote machine ie. need a root
# password.
#
# If command line arg is used it specifies the last octet of the remote
# machine IP address.
# The root IP address is specified in variable DSTADDR.
# Full IP address is $DSTADDR.$IPADDR
#
# If $DEBUG is defined it will not copy to remote machine.  Verify what
# would have been copied to remote machine in directory: $TMP_BOOTDIR
#
# Debug flag to show what would be copied without doing the copy
DRY_RUN="false"

IPADDR="117"
DSTADDR=

FULL_UPDATE=true
KERNEL=kernel7

SRC_DIR="$(pwd)/kern"
SRC_BOOTDIR="$SRC_DIR/boot"

TMP_BOOTDIR="$(pwd)/tmpboot"

# Don't run as root
if [[ $EUID -eq 0 ]]; then
  echo "*** Run as user not root" 2>&1
  exit 1
fi

# Check for any arguments
if (( $# != 0 )) ; then
   IPADDR="$1"
fi

DSTADDR="10.0.42.$IPADDR"

# Check for required source directory
if [ ! -d $SRC_DIR ] ; then
   echo "Directory: $SRC_DIR does not exist."
   echo "Need to run kern_cpy_local.sh first."
   exit 1
fi

echo "Copy files to target machine: $DSTADDR"

# Copy file system partition files to remote machine
SRC_FILE="$SRC_DIR/lib/modules/*"
DST_FILE="/lib/modules/"
if [ "$DRY_RUN" = "true" ] ; then
   echo "Dry run only, no module files copied to remote machine, check dir: $SRC_FILE"
else
   echo "Copy /lib/modules to remote ext4 partition..."
   if [ "$FULL_UPDATE" == "true" ] ; then
      rsync -azu --exclude=".*" -e ssh $SRC_FILE root@$DSTADDR:$DST_FILE
      if [ $? -ne 0 ] ; then
         echo "Problem copying to remote modules dir: $DST_FILE"
         exit 1
      fi
   fi
fi

# Make a tmp dir & aggregate all /boot partition files to it
if [ ! -d $TMP_BOOTDIR ] ; then
   mkdir -p $TMP_BOOTDIR/overlays
   echo "Made directory $TMP_BOOTDIR/overlays"
fi

echo "Copy a new kernel image to tmp boot"
SRC_FILE="$SRC_BOOTDIR/zImage"
DST_FILE="$TMP_BOOTDIR/$KERNEL.img"
rsync -azu $SRC_FILE $DST_FILE
if [ $? -ne 0 ] ; then
   echo "Problem copying files: $SRC_FILE to $DST_FILE"
   exit 1
fi

echo "Copy dtb files to tmp boot"
SRC_FILE="$SRC_BOOTDIR/dts/*.dtb"
DST_FILE="$TMP_BOOTDIR"
rsync -azu $SRC_FILE $DST_FILE
if [ $? -ne 0 ] ; then
   echo "Problem copying file: $SRC_FILE to $DST_FILE"
   exit 1
fi

echo "copy overlay files to tmp boot"
SRC_FILE="$SRC_BOOTDIR/dts/overlays/*.dtb*"
DST_FILE="$TMP_BOOTDIR/overlays"
rsync -azu $SRC_FILE $DST_FILE
if [ $? -ne 0 ] ; then
   echo "Problem copying files: $SRC_FILE to $DST_FILE"
   exit 1
fi

# Copy boot partition files to remote machine
SRC_FILE="$TMP_BOOTDIR/*"
DST_FILE="/boot"
if [ "$DRY_RUN" = "true" ] ; then
   echo "Dry run only, no boot files copied to remote machine, check dir: $SRC_FILE"
else
   echo "Copy files to remote /boot partition"
   rsync -azuv --exclude=".*" -e ssh $SRC_FILE root@$DSTADDR:$DST_FILE
   if [ $? -ne 0 ] ; then
      echo "Problem copying to remote boot dir: $SRC_FILE"
      exit 1
   fi
fi

exit 0
