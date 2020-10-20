#!/bin/bash
#
# Verify Linux RMS Gatway for Winlink automatic check-in
#
# DEBUG=1

scriptname="`basename $0`"

AX25_CFGDIR="/usr/local/etc/ax25"
AXPORTS_FILE="$AX25_CFGDIR/axports"

if [ -e /etc/rmsgw/channels.xml ] ; then
    rmsgw_dir="/etc/rmsgw"
elif [ -e /usr/local/etc/rmsgw/channels.xml ] ; then
    rmsgw_dir="usr/local/etc/rmsgw"
else
    echo "rmsgw etc files do not exist!"
    exit 1
fi

echo "==== Check stat directory"
ls  -al /etc/rmsgw/stat

echo
echo "==== Check rmsgw automatic check-in at $(date)"

# get the first port line after the last comment
#axports_line=$(tail -n3 $AXPORTS_FILE | grep -v "#" | grep -v "N0ONE" |  head -n 1)
axports_line=$(tail -n3 $AXPORTS_FILE | grep -vE "^#|N0ONE" |  head -n 1)

echo "Using axports line: $axports_line"
port=$(echo $axports_line | cut -d' ' -f1)
callsign=$(echo $axports_line | tr -s '[[:space:]]' | cut -d' ' -f2)
echo "Using port: $port, call sign: $callsign"

echo " Verify rmschanstat"
sudo -u rmsgw rmschanstat ax25 $port $callsign
echo " Verify rmsgw_aci"
sudo -u rmsgw rmsgw_aci

echo
echo "==== Check rmsgw crontab entry"
# List crontab entries without displaying the comment lines
sudo -u rmsgw crontab -l | grep -vE '^#'
echo

echo
echo "==== Check rmsgw log file"
tail /var/log/rms

echo "==== $scriptname finished at $(date)"
