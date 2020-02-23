#!/bin/bash

AX25_DEVICE_DIR="/proc/sys/net/ax25"
# AX25_KISS_CFG="/etc/systemd/system/ax25dev.service"
AX25_KISS_CFG="/etc/ax25/ax25-upd"
PORT_CFG_FILE="/etc/ax25/port.conf"

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
# Assume there are ONLY 2 modems configured
# in direwolf configuration file
dire_udr0_baud=$(grep -i "^MODEM " /etc/direwolf.conf | cut -d ' ' -f2 | head -n 1)
dire_udr1_baud=$(grep -i "^MODEM " /etc/direwolf.conf | cut -d ' ' -f2 | tail -n 1)
echo "DireWolf: udr0 speed: $dire_udr0_baud, udr1 speed: $dire_udr1_baud"

if [ -e $PORT_CFG_FILE ] ; then
    echo
    echo "===== ax25"
    ax25_udr0_baud=$(sed -n '/\[port0\]/,/\[/p' $PORT_CFG_FILE | grep -i "^speed" | cut -f2 -d'=')
    ax25_udr1_baud=$(sed -n '/\[port1\]/,/\[/p' $PORT_CFG_FILE | grep -i "^speed" | cut -f2 -d'=')
    echo "AX.25: udr0 speed: $ax25_udr0_baud, udr1 speed: $ax25_udr1_baud"
else
    echo "Port config file: $PORT_CFG_FILE NOT found."
fi

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
