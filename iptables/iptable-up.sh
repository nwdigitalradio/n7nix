#!/bin/bash

# ===== function is_ax25up
function is_ax25up() {
    ax25device=$1
    ip a show $ax25device up > /dev/null  2>&1
}

# ===== main

device="ax0"
is_ax25up "$device"
if [ "$?" -eq 0 ] ; then
    iptables -A OUTPUT -o "$device" -d 224.0.0.22 -p igmp -j DROP
    iptables -A OUTPUT -o "$device" -d 224.0.0.251 -p udp -m udp --dport 5353 -j DROP
    iptables -A OUTPUT -o "$device" -d 239.255.255.250 -p udp -m udp  -j DROP
fi

device="ax1"
is_ax25up "$device"
if [ "$?" -eq 0 ] ; then
    iptables -A OUTPUT -o "$device" -d 224.0.0.22 -p igmp -j DROP
    iptables -A OUTPUT -o "$device" -d 224.0.0.251 -p udp -m udp --dport 5353 -j DROP
    iptables -A OUTPUT -o "$device" -d 239.255.255.250 -p udp -m udp  -j DROP
fi
