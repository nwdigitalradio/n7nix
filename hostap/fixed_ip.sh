#!/bin/bash
#
# Set a fixed lan ip address
#  Usage: $scriptname [-l][-s][-w][-d][-h] last_ip_octet or complete ip address
#
# Edit file:
#  /etc/dhcpcd.conf
# Check file:
#  /etc/network/interfaces
#
#DEBUG=1
DEBUG_MODE="false"
DEBUG_RESET_NETWORKING="false"
SET_WIFI_IPADDR="false"

scriptname="`basename $0`"
lanif="eth0"
#lanif="enp3s0"

# WiFi ip address Should be on a different subnet than Lan ip address
wan_ipaddr="10.0.44.1"
ip_parse=

# ===== function debugecho

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function valid_ip

# Copied from here:
# http://www.linuxjournal.com/content/validating-ip-address-bash-script
#
# Test an IP address for validity:
# Usage:
#      valid_ip IP_ADDRESS
#      if [[ $? -eq 0 ]]; then echo good; else echo bad; fi
#   OR
#      if valid_ip IP_ADDRESS; then echo good; else echo bad; fi
#
function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# ===== function set_static_lan

function set_static_lan()
{
iface="$lanif"
echo "$scriptname: writing files for static LAN ip address"
fname="/etc/dhcpcd.conf"
grep -i "interface $iface" $fname > /dev/null 2>&1
if [ $? -ne 0 ] ; then
   cat <<EOT >> $fname

interface $iface

  static ip_address=$1/24
  static routers=$2
  static domain_name_servers=$2

EOT

else
   echo "$scriptname: file $fname already config'ed, edit manually"
fi

fname="/etc/network/interfaces"
grep -i "iface $iface inet manual" $fname > /dev/null 2>&1
if [ $? -ne 0 ] ; then
   cat <<EOT >> $fname
iface $iface inet manual
EOT
else
   echo "$scriptname: file $fname already config'ed OK"
fi
}
# ===== function set_static_wan

function set_static_wan()
{
iface="wlan0"
echo "$scriptname: writing files for static WAN ip address"

ip_addr=$1
ip_root=${ip_addr%.*}
network_addr="$ip_root.0"
bcast_addr="$ip_root.255"

fname="/etc/dhcpcd.conf"
grep -i "interface $iface" $fname > /dev/null 2>&1
if [ $? -ne 0 ] ; then

cat <<EOT >> /etc/dhcpcd.conf

interface $iface

  static ip_address=$1/24
EOT
else
   echo "$scriptname: file $fname already config'ed, edit manually"
fi

fname="/etc/network/interfaces"
grep -i "iface $iface inet static" $fname > /dev/null 2>&1
if [ $? -ne 0 ] ; then
   cat <<EOT >> /etc/network/interfaces
allow-hotplug wlan0
iface wlan0 inet static
  address $ip_addr
  netmask 255.255.255.0
  network $network_addr
  broadcast $bcast_addr
EOT

else
   echo "$scriptname: file $fname already config'ed edit manually"
fi
}

# ===== function usage

function usage() {
   echo "Usage: $scriptname [-l][-s][-w][-d][-h] last_ip_octet or complete ip address"
   echo "   -l --link  show all devices that have link"
   echo "   -s --show  show all devices with ip4 addresses"
   echo "   -w --wifi  set wifi address"
   echo "   -d --debug set debug mode, will not change any files"
   echo "   -h display this message"
   echo
}

# ===== main

# Check if $lanif network interface is already up
ifcheck=$(grep -i $lanif /etc/network/interfaces)
retcode=$?
# Does $lanif exist?
if [ $retcode -eq 0 ] ; then
   ip_current=$(ip addr show $lanif | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
   ip_root=${ip_current%.*}
fi

# parse any args on command line
if (( $# != 0 )) ; then
   while [[ $# -gt 0 ]] ; do
   key="$1"

   case $key in
      -d|--debug)
         DEBUG_MODE="true"
      ;;
      -s|--show)
         ip -4 -o addr | awk '!/^[0-9]*: ?lo|link\/ether/ {gsub("/", " "); print $2" "$4}'
	 exit 0
      ;;
      -l|--link)
         ip -o link show | awk '{print $2,$9}'
	 exit 0
      ;;
      -w|--wifi)
         SET_WIFI_IPADDR="true"
      ;;
      -?|-h|--help)
         usage
         exit 0
      ;;
      *)
# Anything else on command line
# IP address or last octet of ip address
         ip_parse="$1"
      ;;
   esac
   shift # past argument or value
done
fi

# Be sure we're running as root
if [[ "$DEBUG_MODE" = "false" ]] && [[ $EUID != 0 ]] ; then
   echo "Must be root."
   exit 1
fi

if [[ -z $ip_parse ]] ; then
   echo -n "Enter entire ip address or last octet for $ip_root followed by [enter]"
   read -ep ": " ip_parse
fi

count_dots=$(grep -o "\." <<< "$ip_parse" | wc -l)
dbgecho "Number of dots in var: $ip_parse $count_dots"

case $count_dots in
   0)
      dbgecho "ip check no dots: $ip_parse"
      ip_addr="$ip_root.$ip_parse"
   ;;
   3)
      dbgecho "ip check 3 dots: $ip_parse"
      ip_addr=$ip_parse
   ;;
   *)
      echo "Invalid entery: $ip_parse, expect complete ip address or last octet"
      exit 1
   ;;
esac

valid_ip $ip_addr
retcode=$?


if [ $retcode -eq 1 ] ; then
   echo "Invalid IP address: $ip_addr"
   exit 1
else
   echo "Valid ip address: $ip_addr"
fi

ip_root=${ip_addr%.*}
lan_router=$(echo "$ip_root.1")
lan_ipaddr=$ip_addr

echo "ip addr: $lan_ipaddr, lan router: $lan_router, ip root: $ip_root"

# if DEBUG_MODE is true don't write any files
if [ "$DEBUG_MODE" = "false" ] ; then

# Set either WiFi or Lan fixed ip address not both
   if [ "SET_WIFI_IPADDR" = "true" ] ; then
      set_static_wlan $wan_ipaddr
   else
      set_static_lan $lan_ipaddr $lan_router
   fi
else
   echo "$scriptname: Using DEBUG_MODE, no files written"
fi

# Not sure how to enable new ip address
if [ "$DEBUG_RESET_NETWORKING" = "true" ] ; then
   echo "You are about to lose your SSH session"
   echo "Login in using lan address: $lan_ipaddr or wlan address: $wlan_ipaddr"
   systemctl is-enabled NetworkManager.service
   if [ $? -eq 0 ] ; then
      echo "Disabling Network Manager"
      systemctl disable NetworkManager.service
   fi
   systemctl daemon-reload
   systemctl restart dhcpcd.service
   service networking restart
fi

echo
echo "Fixed IP address config FINISHED"
echo
