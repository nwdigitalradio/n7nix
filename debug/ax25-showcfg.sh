#!/bin/bash

AX25_DEVICE_DIR="/proc/sys/net/ax25"
# AX25_KISS_CFG="/etc/systemd/system/ax25dev.service"
AX25_KISS_CFG="/etc/ax25/ax25-upd"

echo " ===== packet baud rate"
# For 9600 baud packet
if [ -e "/etc/ax25/packet_9600baud" ] ; then
    CFG_BAUDRATE="9600"
else
    CFG_BAUDRATE="1200"
fi
echo "Configured for $CFG_BAUDRATE baud"

echo
echo " ===== kissparms"
MATCHLINE=2
if [ "$CFG_BAUDRATE" == "1200" ] ; then
    MATCHLINE=1
fi

grep -m $MATCHLINE -A 1 -i slottime $AX25_KISS_CFG | tail -n 2
grep -i "kissparms" $AX25_KISS_CFG

echo
echo " ===== ax.25 config"
for dir in $AX25_DEVICE_DIR/* ; do
    echo "Found directory: $dir"
    for file in $dir/* ; do
	fname="$(basename -- "$file")"
	echo -n "$fname: "
	cat $file
    done
    echo
done

# display alsa settings
echo
alsa-show.sh

echo
echo "===== direwolf"
udr0_baud=$(grep -i "^MODEM " /etc/direwolf.conf | cut -d ' ' -f2 | head -n 1)
udr1_baud=$(grep -i "^MODEM " /etc/direwolf.conf | cut -d ' ' -f2 | tail -n 1)
echo "udr0 speed: $udr0_baud"
echo "udr1 speed: $udr1_baud"

# display axports
echo
echo "===== axports"
tail -n 2 /etc/ax25/axports

# display ax25d.conf
echo
echo " ===== ax25d.conf"
CALLSIGN=$(grep -m 1 "^MYCALL" /etc/direwolf.conf | cut -d' ' -f2)
grep -A 25 -i "$CALLSIGN" /etc/ax25/ax25d.conf

# display port in wl2k.conf
echo
echo " ===== wl2k.conf"
grep "ax25port=" /usr/local/etc/wl2k.conf
echo
