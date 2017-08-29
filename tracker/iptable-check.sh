#!/bin/bash
# -L list: List all rules in all chains
# -v verbose output
# -n numeric: IP addresses & port numbers are printed in numeric format
# -x exact: display exact value of the packet & byte counters instead
#    of rounded number
iptables -L -nvx
