#!/bin/bash
#
# Verify Linux RMS Gatway configuration
#
# DEBUG=1
CHECK_WINLINK_CHECKIN=1

scriptname="`basename $0`"
USER="pi"
AXPORTS_FILE="/etc/ax25/axports"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== main

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root"
   exit 1
fi

if [ ! -d /home/$USER ] ; then
    echo "user $USER does not exist"
    exit 1
fi

echo "==== $scriptname start at $(date)"

# Does rmsgw group exist?

echo
echo "==== Check rmsgw group name"
GROUP="rmsgw"

if [ $(getent group $GROUP) ]; then
    echo "group $GROUP exists."
else
    echo "group $GROUP does not exist...adding"
     /usr/sbin/groupadd $GROUP
    usermod -a -G rmsgw rmsgw
fi

echo
echo "==== Check ax.25 device names"

ifconfig ax0
ifconfig ax1

echo
echo "==== Check ax.25 status"

/home/$USER/bin/ax25-status
/home/$USER/bin/ax25-status -d

echo
echo "==== Check ax.25 daemon config file"
cat /etc/ax25/ax25d.conf

echo
echo "==== Check rmsgw configuration directory"
ls -al /etc/rmsgw
ls -al /usr/local/etc/rmsgw
echo "==== Check stat directory"
ls  -al /etc/rmsgw/stat

if [ -e /etc/rmsgw/channels.xml ] ; then
    rmsgw_dir="/etc/rmsgw"
elif [ -e /usr/local/etc/rmsgw/channels.xml ] ; then
    rmsgw_dir="usr/local/etc/rmsgw"
else
    echo "rmsgw etc files do not exist!"
    exit 1
fi

echo
echo "==== Check rmsgw channels file"
cat $rmsgw_dir/channels.xml

if [ -e /etc/rmsgw/channels.xml ] && [ -e /usr/local/etc/rmsgw/channels.xml ] ; then
    diff /etc/rmsgw/channels.xml /usr/local/etc/rmsgw/channels.xml
fi

echo
echo "==== Check rmsgw gateway.conf file"
cat $rmsgw_dir/gateway.conf

echo
echo "==== Check ax.25 axports file"
tail -n3 $AXPORTS_FILE

echo
echo "==== Verify system version"
/home/$USER/bin/sysver.sh

echo
echo "==== Verify start & stop ax.25"
echo
echo "=== ax25-stop at $(date)"

/home/$USER/bin/ax25-stop

sleep 4

echo
echo "=== ax25-start at $(date)"

/home/$USER/bin/ax25-start

echo
echo "=== ax25-status"

/home/$USER/bin/ax25-status -d

echo
echo "==== Check rmsgw automatic check-in at $(date)"
# get the first port line after the last comment
axports_line=$(tail -n3 $AXPORTS_FILE | grep -v "#" | head -n 1)

echo "Using axports line: $axports_line"
port=$(echo $axports_line | cut -d' ' -f1)
callsign=$(echo $axports_line | tr -s '[[:space:]]' | cut -d' ' -f2)
echo "Using port: $port, call sign: $callsign"

if [ ! -z "$CHECK_WINLINK_CHECKIN" ] ; then
    echo " Verify rmschanstat"
    sudo -u rmsgw rmschanstat ax25 $port $callsign
    echo " Verify rmsgw_aci"
    sudo -u rmsgw rmsgw_aci
else
    echo "NO CHECK for Winlink automatic check-in"
fi

echo
echo "==== Check rmsgw log file"
tail /var/log/rms

echo "==== $scriptname finished at $(date)"

