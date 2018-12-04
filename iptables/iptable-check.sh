#!/bin/bash
#
SU=

# Check for required iptables files
#
IPTABLES_FILES="/etc/iptables/rules.ipv4.ax25 /lib/dhcpcd/dhcpcd-hooks/70-ipv4.ax25"
for ipt_file in `echo ${IPTABLES_FILES}` ; do

   if [ -f $ipt_file ] ; then
      echo "iptables file: $ipt_file exists"
   else
      echo "Need to create iptables file: $ipt_file"
   fi
done

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   SU="sudo"
fi

# List iptables rules
#
# -L list: List all rules in all chains
# -v verbose output
# -n numeric: IP addresses & port numbers are printed in numeric format
# -x exact: display exact value of the packet & byte counters instead
#    of rounded number
$SU iptables -L -nvx
