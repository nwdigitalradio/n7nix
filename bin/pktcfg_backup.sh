#!/bin/bash
#
# pktcfg_backup.sh
#
# - Backup serveral of the packet config files
# - initially used to test changing config files.

scriptname="`basename $0`"
USER=$(whoami)
BACKUP_DIR="/home/$USER/backup"

AX25_CFGDIR="/usr/local/etc/ax25"
AXPORTS_FILE="$AX25_CFGDIR/axports"
AX25D_FILE="$AX25_CFGDIR/ax25d.conf"
RMSGW_CHAN_FILE="/etc/rmsgw/channels.xml"
PLU_CFG_FILE="/usr/local/etc/wl2k.conf"

FILE_LIST="$AXPORTS_FILE $AX25D_FILE $RMSGW_CHAN_FILE $PLU_CFG_FILE"

if [ ! -e "$BACKUP_DIR" ] ; then
    mkdir -p "$BACKUP_DIR"
fi

for filename in `echo ${FILE_LIST}` ; do
    echo "copy $filename to $BACKUP_DIR"
    cp $filename $BACKUP_DIR
done

ls -sal $BACKUP_DIR