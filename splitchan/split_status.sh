#!/bin/bash
#
# Mainly for use with DRAWS hat to toggle between having direwolf
# control both channels or just one for HF use on the other

# In this example when configured for split channels:
#  - HF programs use the left mDin6 connector (GPIO 12)
#  - packet programs will use the right connector (GPIO 23)

# Split channel is enabled by having a file (split_channel) in
# directory /etc/ax25

# Uncomment this statement for debug echos
DEBUG=1

bsplitchannel=false
SPLIT_CHANNEL_FILE="/etc/ax25/split_channel"
DIREWOLF_CFGFILE="/etc/direwolf.conf"
AX25_CFGDIR="/usr/local/etc/ax25"
AX25PORT="udr"

# ===== function ax25_status

function ax25_status() {

    device="ax0"
    ip addr show dev $device > /dev/null 2>&1
    if [ "$?" -ne 0 ] ; then
        echo "AX.25 device: $device not configured"
    else
        ipaddr=$(ip addr show dev $device | grep "inet " | grep -Po '(\d+\.){3}\d+' | head -1)
        echo "AX.25 device: $device successfully configured with ip: $ipaddr"
    fi

    device="ax1"
    ip addr show dev $device > /dev/null 2>&1
    if [ "$?" -ne 0 ] ; then
        echo "AX.25 device: $device not configured"
    else
        ipaddr=$(ip addr show dev $device | grep "inet " | grep -Po '(\d+\.){3}\d+' | head -1)
        echo "AX.25 device: $device successfully configured with ip: $ipaddr"
    fi
}

# ===== main

echo

if [ -e "$SPLIT_CHANNEL_FILE" ] ; then
    echo " == Split channel is enabled, Direwolf controls 1 channel"
    echo
    bsplitchannel=true
    echo "pulseaudio daemon status"
    systemctl --no-pager status pulseaudio


else
    echo " == Direwolf controls both channels, split-channels is off"
    echo
    bsplitchannel=true
fi


# check direwolf config file
echo
echo " == Verify direwolf config"

file="$DIREWOLF_CFGFILE"
echo "First occurrence in $file"
grep -m1 "^ADEVICE"   "$file"
grep -m1 "^ACHANNELS" "$file"
grep -m1 "^PTT "  "$file"

echo "Second occurrence in $file"
grep -m1 "^#ADEVICE"   "$file" | tail -n1
grep -m1 "^#ACHANNELS" "$file" | tail -n1
grep -m1 "^PTT "  "$file" | tail -n1

echo
echo " == check ax25d file"

file="/etc/ax25/ax25d.conf"
echo "First occurrence in $file"
grep -m1 "^\[" "$file"
echo "Second occurrnece in $file"
grep "^\[" "$file" | tail -n1

# check axports file

echo
echo " == check axports file"
file="$AX25_CFGDIR/axports"
numports=$(grep -c "^$AX25PORT" $AX25_CFGDIR/axports)
echo "AX.25 $AX25PORT configured with $numports port(s)"

# get the first port line after the last comment
tail -n3 $file | grep -v "#"

# check ax25 status

echo
echo "ax25 status"
ax25_status
