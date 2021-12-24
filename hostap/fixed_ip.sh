#!/bin/bash
#
# Set a fixed lan ip address
#  Usage: fixed_ip.sh [-l][-s][-w][-d][-h] last_ip_octet or
#          complete ip address
#
# NOTE: For this script to work must get rid of persistence
#  Delete these files:
#   /var/lib/dhcpcd/<interface>.lease
#   /var/lib/dhcpcd/<interface-ssid>.lease
#   /var/lib/dhcpcd/duid
#
# Edit file:
#  /etc/dhcpcd.conf
# Check file:
#  /etc/network/interfaces
#
DEBUG=

# When set to true no files are written
DEBUG_MODE="false"

DEBUG_RESET_NETWORKING="false"
SET_WIFI_IPADDR="false"
SYSTEMCTL="systemctl"

scriptname="`basename $0`"
lanif="eth0"
#lanif="enp3s0"
if_file="/etc/network/interfaces"
NETPLAN_CFG_DIR="/etc/netplan"
NETPLAN_CFG_FILE="$NETPLAN_CFG_DIR/01-netcfg.yaml"

# WiFi ip address Should be on a different subnet than Lan ip address
wan_ipaddr="10.0.44.1"
ip_parse=

# ===== function debugecho

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function cidr_to_netmask

# Copied from here:
# https://gist.github.com/kwilczynski/5d37e1cced7e76c7c9ccfdf875ba6c5b
#
# CIDR to netmask in bash.
# Return netmask for a given network and CIDR.

cidr_to_netmask() {
    value=$(( 0xffffffff ^ ((1 << (32 - $2)) - 1) ))
    echo "$(( (value >> 24) & 0xff )).$(( (value >> 16) & 0xff )).$(( (value >> 8) & 0xff )).$(( value & 0xff ))"
}

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

    need_manual_edit="false"

    # Determine if all 'interface eth0' lines are commented.
    while read -r line ; do
        dbgecho "Processing $line"
        # your code goes here
        if [[ ${line:0:1} == "#" ]] ; then
            dbgecho "Found comment char"
        else
            dbgecho "No comment"
            need_manual_edit="true"
        fi
    done < <(grep -i "interface $iface" $fname)

    # if an uncommented "interface eth0 line is found then have to edit
    # manually.

    if [[ "$need_manual_edit" != "true" ]] ; then
        sudo tee $fname > /dev/null << EOT

interface $iface

  static ip_address=$1/24
  static routers=$2
  static domain_name_servers=1.1.1.1 9.9.9.9 $2

EOT

    else
        echo "$scriptname: file $fname already config'ed, edit manually"
    fi

    grep -i "^iface $iface inet manual" $if_file > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        sudo tee $if_file > /dev/null <<EOT
iface $iface inet manual
EOT
    else
        echo "$scriptname: file $if_file already config'ed OK"
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
grep -i "interface $iface" $if_file > /dev/null 2>&1
if [ $? -ne 0 ] ; then

sudo tee $fname > /dev/null <<EOT

interface $iface
  static ip_address=$1/24
  static routers=${ip_root}.1
  static domain_name_servers ${ip_root}.1 8.8.8.8
EOT
else
   echo "$scriptname: file $if_file already config'ed, edit manually"
fi

grep -i "iface $iface inet static" $if_file > /dev/null 2>&1
if [ $? -ne 0 ] ; then
   sudo tee $if_file > /dev/null <<EOT
allow-hotplug $iface
iface $iface inet static
  address $ip_addr
  netmask 255.255.255.0
  network $network_addr
  broadcast $bcast_addr
EOT

else
   echo "$scriptname: file $if_file already config'ed, edit manually"
fi
}

# ===== function display_eth_addrlink

function display_eth_addrlink() {
    echo "Iterate through all Ethernet devices"
    netdevice_list=$(grep "^en\|^eth" <<< $(ls /sys/class/net))
#    dbgecho "netdevice list: $netdevice_list"

    for ethdev in $(echo ${netdevice_list}) ; do
        ipaddr=$(ip -4 -o addr show dev $ethdev | awk '!/^[0-9]*: ?lo|link\/ether/ {gsub("/", " "); print $2" "$4}')
        ipaddr=$(echo $ipaddr | cut -f2 -d' ')
        ip_root=${ipaddr%.*}
        linkstat=$(ip -o link show dev $ethdev | awk '{print $2,$9}' | cut -f2 -d' ')

        if [ -z "$ipaddr" ] ; then
            echo "No ip adddress found on Interface: $ethdev"
        else
            echo "$ethdev: $ipaddr, root ip: $ip_root, Link: $linkstat"
        fi
    done
}

# ===== function status_service

function status_service() {

    service="$1"
    retcode=0

    IS_ENABLED="ENABLED"
    IS_RUNNING="RUNNING"
    # echo "Checking service: $service"
    systemctl is-enabled "$service" > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        IS_ENABLED="NOT ENABLED"
        retcode=1
    fi
    systemctl is-active "$service" > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        IS_RUNNING="NOT RUNNING"
        retcode=1
    fi
    return $retcode
}

# ===== function check_services
function check_services() {
    # What's running:

    service="networking"
    status_service $service
    bnetworking_status="$?"
    echo "Status for $service: $IS_RUNNING and $IS_ENABLED"

    service="systemd-networkd"
    status_service $service
    bsystemd_networkd_status="$?"
    echo "Status for $service: $IS_RUNNING and $IS_ENABLED"

    service="network-manager"
    status_service $service
    bnetwork_manager_status="$?"
    echo "Status for $service: $IS_RUNNING and $IS_ENABLED"
}

# ===== function restart_networking_new

function restart_networking_new() {
    netplan apply
    $SYSTEMCTL stop networking.service
}

# ===== function restart_networking_old

function restart_networking_old() {

    # Not sure how to enable new ip address
    if [ "$DEBUG_RESET_NETWORKING" = "true" ] ; then
        echo "You are about to lose your SSH session"
        echo "Login in using lan address: $lan_ipaddr or wlan address: $wlan_ipaddr"
        systemctl is-enabled NetworkManager.service
        if [ $? -eq 0 ] ; then
          echo "Disabling Network Manager"
          $SYSTEMCTL disable NetworkManager.service
        fi
        $SYSTEMCTL daemon-reload
        $SYSTEMCTL --no-pager restart dhcpcd.service
        sudo service networking restart
    fi
}

# ===== function check_network_style

function check_network_style() {
    # Set flag to use systemd-neworkd & netplan
    networking_style="new"

    if [ -d $NETPLAN_CFG_DIR ] ; then
        echo "Netplan configuration directory found."
        if [ ${bsystemd_networkd_status} = 0 ] || [ ${bnetwork_manager} = 0 ] ; then
            echo "Configuring network interfaces with systemd-networkd + netplan"
        else
            echo "Have netplan configuration but systemd-networkd or network-manager not running."
        fi
    else
        echo "Configuring Network interfaces with ifupdown."
        networking_style="old"
    fi
    echo
}

# ===== check_network_device
function check_network_device() {
    # Find name of Ethernet device(s)
    # look at /sys/class/net for enx or ethx device names
    device_list=$(ls /sys/class/net | tr '\n' ' ' |tr -s '[[:space:]] ')
    #dbgecho "device list: $device_list"
    device_cnt=$(ls -1 /sys/class/net | wc -l)
    netdevice_cnt=$(grep -c "^en\|^eth" <<< $(ls /sys/class/net))
    echo "Found $device_cnt network devices. $netdevice_cnt Ethernet devices"

    if [ "$netdevice_cnt" -gt 0 ] ; then
        display_eth_addrlink
        echo
    else
        echo "No Ethernet devices found."
        exit 1
    fi
}

# ===== function set_dhcp
# Configure Etherenet device to use DHCP

function set_dhcp() {
    # Modify /etc/network/interface
    sudo sed -i -e '/iface eth0/d' $if_file

    # Modify /etc/dhcpcd.conf
    sudo sed -i -e '/^interface eth0/,$d' /etc/dhcpcd.conf
}

# ===== function usage

function usage() {
   echo "Usage: $scriptname [-l][-s][-w][-y][-d][-h] last_ip_octet or complete ip address"
   echo " Default to setting a static ip address"
   echo "   -y --dhcp  set Ethernet device to use DHCP"
   echo "   -l --link  show all devices that have link"
   echo "   -s --show  show all devices with ip4 addresses"
   echo "   -w --wifi  set wifi address"
   echo "   -d --debug set debug mode, will not change any files"
   echo "   -h display this message"
   echo
   exit 0
}

# ===== main

if [ ! -z "$DEBUG" ] ; then
    check_services
fi

check_network_style
check_network_device

if [ 1 -eq 0 ] ; then

# Check if $lanif network interface is already up
ifcheck=$(grep -i $lanif $if_file)
retcode=$?
# Does $lanif exist?
dbgecho "Check for interface: $lanif"
if [ $retcode -eq 0 ] ; then
   echo "Found lan interface: $lanif in $if_file"
else
   echo "Lan interface: $lanif, does not exist in $if_file"
fi

fi

# parse any args on command line
if (( $# != 0 )) ; then
   while [[ $# -gt 0 ]] ; do
   key="$1"

   case $key in
      -y|--dhcp)
          echo "Set DHCP address"
          set_dhcp
          exit 0
      ;;
      -d|--debug)
          DEBUG_MODE="true"
	  DEBUG=1
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
       ;;
      *)
         # Anything else on command line
         # IP address or last octet of ip address
         ip_parse="$1"
         re='[0-9]+$'
         if ! [[ $ip_parse =~ $re ]] ; then
             echo "Invalid argument: $ip_parse"
             usage
         fi
      ;;
   esac
   shift # past argument or value
done
fi

# setup systemctl command, run as root
if [[ "$DEBUG_MODE" = "false" ]] && [[ $EUID != 0 ]] ; then
   SYSTEMCTL="sudo systemctl"
   echo "Running as user $(whoami)"
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

ip_current="$ipaddr"
dbgecho "ip current: $ip_current, ip root: $ip_root"

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
   if [ "$SET_WIFI_IPADDR" = "true" ] ; then
      set_static_wan $wan_ipaddr
   else
      set_static_lan $lan_ipaddr $lan_router
   fi
else
   echo "$scriptname: Using DEBUG_MODE, no files written"
fi

if [ "$networking_style" = "old" ] ; then
   echo "DEBUG: network style: $networking_style"
   restart_networking_old
else
   restart_networking_new
fi

sleep 2
networkctl list

echo
echo "Fixed IP address config FINISHED"
echo
