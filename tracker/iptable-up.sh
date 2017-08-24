#!/bin/bash
iptables -A OUTPUT -o ax0 -s 224.0.0.22 -p UDP -j DROP
iptables -A INPUT -i ax0 -s 224.0.0.22 -p UDP -j DROP
iptables -A FORWARD -i ax0 -s 224.0.0.22 -p UDP -j DROP

iptables -A OUTPUT -o ax0 -d 224.0.0.22 -p UDP -j DROP
iptables -A INPUT -i ax0 -d 224.0.0.22 -p UDP -j DROP
iptables -A FORWARD -i ax0 -d 224.0.0.22 -p UDP -j DROP

iptables -A OUTPUT -o ax0 -s 224.0.0.251 -p igmp -j DROP
iptables -A INPUT -i ax0 -s 224.0.0.251 -p igmp -j DROP
iptables -A FORWARD -i ax0 -s 224.0.0.251 -p igmp -j DROP

iptables -A OUTPUT -o ax0 -d 224.0.0.251 -p igmp -j DROP
iptables -A INPUT -i ax0 -d 224.0.0.251 -p igmp -j DROP
iptables -A FORWARD -i ax0 -d 224.0.0.251 -p igmp -j DROP

iptables -A OUTPUT -o ax0 -s 224.0.0.251 -p udp -m udp --dport 5353 -j DROP
iptables -A INPUT -i ax0 -s 224.0.0.251 -p udp -m udp --dport 5353 -j DROP
iptables -A FORWARD -i ax0 -s 224.0.0.251 -p udp -m udp --dport 5353 -j DROP

iptables -A OUTPUT -o ax0 -d 224.0.0.251 -p udp -m udp --dport 5353 -j DROP
iptables -A INPUT -i ax0 -d 224.0.0.251 -p udp -m udp --dport 5353 -j DROP
iptables -A FORWARD -i ax0 -d 224.0.0.251 -p udp -m udp --dport 5353 -j DROP
