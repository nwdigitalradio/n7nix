#!/bin/bash
#
# DEBUG=1

SBINDIR=/usr/local/sbin

AX25IPD_KISSOUT_FILE="/tmp/ax25ipd-config.tmp"
AX25IPD_TMP_FILE="/tmp/ax25ipd-config-tmp"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

echo "Installing ax25ipd Unix98 master pseudo tty"
# specify ax25ipd config file path & log level
$SBINDIR/ax25ipd -c /etc/ax25/ax25ipd.conf -l3 > $AX25IPD_TMP_FILE
retcode="$?"
ax25ipd_pid=$(pidof ax25ipd)
dbgecho "DEBUG: ax25ipd ret: $retcode, pid: $ax25ipd_pid"
if [ "$retcode" -ne 0 ] ; then
    echo "Failed to run ax25ipd"
    # If there is an ax25ipd pid kill it now
    if [ ! -z "$ax25ipd_pid" ] ; then
        kill "$ax25ipd_pid"
    fi
    exit
else
    echo "ax25ipd running with pid: $ax25ipd_pid"
    # Save process id of ax25ipd
    echo "$ax25ipd_pid" > /var/run/ax25ipd.pid
fi

# Get pseudo term device name
AXUDP=$(cat $AX25IPD_TMP_FILE | tail -n1)
dbgecho "DEBUG: AXUDP: $AXUDP"
export AXUDP=$AXUDP

echo "Installing a KISS link with pseudo term: $AXUDP on ethernet port"
$SBINDIR/kissattach  $AXUDP axudp  > $AX25IPD_KISSOUT_FILE
if [ "$?" -ne 0 ] ; then
    echo "Kissattach failed to attach pseudo term: $AXUDP"
    exit
fi

# Get ax25 device name
awk '/device/ { print $7 }' $AX25IPD_KISSOUT_FILE > $AX25IPD_TMP_FILE
read Device < $AX25IPD_TMP_FILE

# Check for ax25 Device
if [ -d /proc/sys/net/ax25/$Device ] ; then
    echo "Port axudp attached to $Device"
else
    echo "Device: $Device does NOT exist"
fi

