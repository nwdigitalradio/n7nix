#!/bin/bash
iptables -A OUTPUT -o ax0 -d 224.0.0.22 -p igmp -j DROP
iptables -A OUTPUT -o ax0 -d 224.0.0.251 -p udp -m udp --dport 5353 -j DROP
iptables -A OUTPUT -o ax0 -d 239.255.255.250 -p udp -m udp  -j DROP
iptables -A OUTPUT -o ax1 -d 224.0.0.22 -p igmp -j DROP
iptables -A OUTPUT -o ax1 -d 224.0.0.251 -p udp -m udp --dport 5353 -j DROP
iptables -A OUTPUT -o ax1 -d 239.255.255.250 -p udp -m udp  -j DROP
