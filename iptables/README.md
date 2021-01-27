### iptable entry descriptions

* Chromium IGMPv2 multicast protocol
```
iptables -A OUTPUT -o "$device" -d 224.0.0.22 -p igmp -j DROP
```

* Bonjour/mDNS request from Avahi daemon
```
iptables -A OUTPUT -o "$device" -d 224.0.0.251 -p udp -m udp --dport 5353 -j DROP
```

* Simple Service Discovery Protocol (SSDP) for uPNP detection
```
iptables -A OUTPUT -o "$device" -d 239.255.255.250 -p udp -m udp  -j DROP
```
* Canon-mfnp port 8610 and Canon-bjnp port 8612
  * [CUPS - Excessive Amounts of UDP Multicast Traffic for BJNP](https://bugs.launchpad.net/ubuntu/+source/cups/+bug/1671974)
```
iptables -A OUTPUT -o "$device" -p udp -m udp --dport 8610 -j DROP
iptables -A OUTPUT -o "$device" -p udp -m udp --dport 8612 -j DROP
```
