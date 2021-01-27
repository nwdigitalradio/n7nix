#!/bin/bash
#
# Enable iptables rules on devices that are up

# ===== function is_ax25up
function is_ax25up() {
    ax25device=$1
    ip a show $ax25device up > /dev/null  2>&1
}

# ===== main

# For each ax25 interface check if it is up and apply iptables rules
for device in "ax0" "ax1" ; do
    echo "Using device: $device"
    is_ax25up "$device"
    if [ "$?" -eq 0 ] ; then
        iptables -A OUTPUT -o "$device" -d 224.0.0.22 -p igmp -j DROP
        iptables -A OUTPUT -o "$device" -d 224.0.0.251 -p udp -m udp --dport 5353 -j DROP
        iptables -A OUTPUT -o "$device" -d 239.255.255.250 -p udp -m udp  -j DROP
	iptables -A OUTPUT -o "$device" -p udp -m udp --dport 8610 -j DROP
	iptables -A OUTPUT -o "$device" -p udp -m udp --dport 8612 -j DROP
    else
        echo "Device: $device NOT UP, iptable rules not applied"
    fi
done
