#!/bin/sh
#
SBINDIR=/usr/local/sbin

AX25IPD_KISSOUT_FILE="/tmp/ax25ipd-config.tmp"
AX25IPD_DEVICE_FILE="/tmp/ax25ipd-config-tmp"

echo "Installing ax25ipd Unix98 master pseudo tty"
AXUDP=$($SBINDIR/ax25ipd -c /etc/ax25/ax25ipd.conf -l3 | tail -1)
# Get process id of ax25ipd
echo $! > /var/run/ax25ipd.pid
export AXUDP
#
echo "Installing a KISS link with pseudo term: $AXUDP on ethernet port"
$SBINDIR/kissattach  $AXUDP axudp  > $AX25IPD_KISSOUT_FILE
 awk '/device/ { print $7 }' $AX25IPD_KISSOUT_FILE > $AX25IPD_DEVICE_FILE
read Device < $AX25IPD_DEVICE_FILE

#Check for Device
if [ -d /proc/sys/net/ax25/$Device ] ; then
    echo "Port axudp attached to $Device"
    cd /proc/sys/net/ax25/$Device/
else
    echo "Device: $Device does NOT exist"
fi

