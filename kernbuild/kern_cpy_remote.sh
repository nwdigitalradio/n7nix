#!/bin/bash
#
# kern_cpy_remote.sh
#

FULL_UPDATE=false
IPADDR="118"
#DEST_DIR=/var/lib/tftpboot
user="$(whoami)"
DEST_DIR=/home/$user/var/lib

# Don't run as root
if [[ $EUID -eq 0 ]]; then
  echo "*** Run as user not root" 2>&1
  exit 1
fi

# Check for any arguments
if (( $# != 0 )) ; then
   IPADDR="$1"
fi

echo "======================"
if [ ! -d $DEST_DIR/lib/modules ] ; then
   mkdir -p $DEST_DIR/lib/modules
fi
if [ ! -d $DEST_DIR/boot/overlays ] ; then
   mkdir -p $DEST_DIR/boot/overlays
fi
echo "Copy files to tftpboot"
rsync  -av ../lib/modules/4.4.33* $DEST_DIR/lib/modules/
if [ $? -ne 0 ] ; then
   echo "Problem coping modules to tftpboot"
   exit 1
fi

cp arch/arm/boot/dts/*.dtb $DEST_DIR/boot/
if [ $? -ne 0 ] ; then
   echo "Problem copying device tree to tftpboot"
   exit 1
fi

cp arch/arm/boot/dts/overlays/*.dtb* $DEST_DIR/boot/overlays/
if [ $? -ne 0 ] ; then
   echo "Problem copying device tree overlays to tftpboot"
   exit 1
fi

scripts/mkknlimg arch/arm/boot/zImage $DEST_DIR/boot/kernel7.img
if [ $? -ne 0 ] ; then
   echo "Problem making kernel image"
   exit 1
fi

echo "============================"
echo "Copy files to target machine: $IPADDR"

if [ "$FULL_UPDATE" == "true" ] ; then
   rsync -azuv -e ssh $DEST_DIR/lib/modules/* root@10.0.42.$IPADDR:/lib/modules/
   if [ $? -ne 0 ] ; then
      echo "Problem rsyncing modules dir"
      exit 1
   fi
fi

rsync -azuv -e ssh $DEST_DIR/boot/* root@10.0.42.$IPADDR:/boot/
if [ $? -ne 0 ] ; then
   echo "Problem rsyncing boot dir"
   exit 1
fi


exit 0
