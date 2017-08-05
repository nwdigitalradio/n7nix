#!/bin/bash
#
# Install a host access point
#
# hosts, resolv.conf /etc/network/interfaces /etc/dhcpcd.conf
DEBUG=1

scriptname="`basename $0`"
SSID="NOT_SET"

# ===== function debugecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }


# ===== function is_rpi3

function is_rpi3() {

CPUINFO_FILE="/proc/cpuinfo"
HAS_WIFI=0

piver="$(grep "Revision" $CPUINFO_FILE)"
piver="$(echo -e "${piver##*:}" | tr -d '[[:space:]]')"

case $piver in
a01040)
   echo " Pi 2 Model B Mfg by Unknown"
;;
a01041)
   echo " Pi 2 Model B Mfg by Sony"
;;
a21041)
   echo " Pi 2 Model B Mfg by Embest"
;;
a22042)
   echo " Pi 2 Model B with BCM2837 Mfg by Embest"
;;
a02082)
   echo " Pi 3 Model B Mfg by Sony"
   HAS_WIFI=1
;;
a22082)
   echo " Pi 3 Model B Mfg by Embest"
   HAS_WIFI=1
;;
esac

return $HAS_WIFI
}

# ===== function copy_dnsmasq
function copy_dnsmasq() {

echo "DEBUG: copy_dnsmasq arg: $1"
if [ -z "$1" ] ; then
   echo "$scriptname: function copy_dnsmasq() needs an argument ... exiting"
   exit 1
fi

# Create a new file
cat > $1/dnsmasq.conf <<EOT
interface=wlan0      # Use interface wlan0
listen-address=10.0.44.1
bind-interfaces      # Bind to the interface to be sure we aren't sending things elsewhere
server=8.8.8.8       # Forward DNS requests to Google DNS
domain-needed        # Don't forward short names
bogus-priv           # Never forward addresses in the non-routed address spaces.
dhcp-range=10.0.44.201,10.0.44.239,12h
EOT
}

# ===== function copy_hostapd

function copy_hostapd() {

echo "DEBUG: copy_hostapd: arg $1"
if [ -z "$1" ] ; then
   echo "$scriptname: function copy_hostapd() needs an argument ... exiting"
   exit 1
fi

# Create a new file

echo "Enter Service set identifier (SSID) for new WiFi access point, followed by [enter]:"
read -e SSID

# Create a new file
cat > $1/hostapd.conf <<EOT
interface=wlan0

# Use the nl80211 driver with the brcmfmac driver
driver=nl80211

# This is the name of the network
ssid=$SSID

# Use the 2.4GHz band
hw_mode=g

# Use channel 7
channel=7

# Enable 802.11n
ieee80211n=1

# Enable WMM
wmm_enabled=1

# Enable 40MHz channels with 20ns guard interval
ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]

# Accept all MAC addresses
macaddr_acl=0

# Require clients to know the network name
#ignore_broadcast_ssid=0

# Use WPA authentication
#auth_algs=1

# Use WPA2
#wpa=2

# Use a pre-shared key
#wpa_key_mgmt=WPA-PSK

# The network passphrase, set password Here
#wpa_passphrase=

# Use AES, instead of TKIP
##wpa_pairwise=CCMP
#rsn_pairwise=CCMP
EOT
}

# ===== function dnsmasq_config

function dnsmasq_config() {

if [ ! -f /etc/dnsmasq.conf ] ; then
   copy_dnsmasq "/etc"
else
   echo "/etc/dnsmasq.conf already exists."
   copy_dnsmasq "/tmp"
   echo "=== diff of current dnsmasq config ==="
   diff -b /etc/dnsmasq.conf /tmp
   echo "=== end diff ==="
fi
}

# ===== hostapd_config

function hostapd_config() {
if [ ! -f /etc/hostapd/hostapd.conf ] ; then
   copy_hostapd "/etc/hostapd"
else
   echo "/etc/hostapd/hostapd.conf already exists."
   copy_hostapd "/tmp"
   echo "=== diff of current dnsmasq config ==="
   diff -b /etc/hostapd/hostapd.conf /tmp
   echo "=== end diff ==="
fi
}


# ===== main

echo "Config hostap on an RPi 3"

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root."
   exit 1
fi

is_rpi3
if [ $? -eq "0" ] ; then
   echo "Not running on an RPi 3 ... exiting"
   exit 1
fi

echo "Configuring: hostapd.conf"
hostapd_config

# edit hostapd to use new config file
sed -i 's;\#DAEMON_CONF="";DAEMON_CONF="/etc/hostapd/hostapd.conf";' /etc/default/hostapd


echo "Configuring: dnsmasq"
if [ -f "/etc/dnsmasq.conf" ] ; then
   dnsmasq_linecnt=$(wc -l /etc/dnsmasq.conf)
   # get rid of everything except line count
   dnsmasq_linecnt=${dnsmasq_linecnt%% *}
   dbgecho "dnsmasq.conf line count: $dnsmasq_linecnt"
   if (("$dnsmasq_linecnt" > "10")) ; then
      mv /etc/dnsmasq.conf /etc/dnsmasq.conf.backup
      echo "Original dnsmasq.conf saved as .backup"
   fi
fi
dnsmasq_config

# set up IPV4 forwarding
echo "Set IPV4 forwarding"
ipf=$(cat /proc/sys/net/ipv4/ip_forward)
echo "ip_forward is $ipf"
if [ $ipf = "0" ] ; then
  sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
fi

sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

echo "setup iptables"
#echo "add iptables-restore to rc.local"
# or use iptables-persistent
CREATE_IPTABLES=false
IPTABLES_FILES="/etc/iptables.ipv4.nat /lib/dhcpcd/dhcpcd-hooks/70-ipv4.nat"
for ipt_file in `echo ${IPTABLES_FILES}` ; do

   if [ -f $ipt_file ] ; then
      echo "iptables file: $ipt_file exists"
   else
      echo "Need to create iptables file: $ipt_file"
      CREATE_IPTABLES=true
   fi
done

if [ "$CREATE_IPTABLES" = "true" ] ; then
   iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
   iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
   iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
   sh -c "iptables-save > /etc/iptables.ipv4.nat"

   iptables -t nat -S
   iptables -S
   cat  > /lib/dhcpcd/dhcpcd-hooks/70-ipv4.nat <<EOF
iptables-restore < /etc/iptables.ipv4.nat
EOF

fi

systemctl daemon-reload
service hostapd start
service dnsmasq start

echo
echo "Test if $SERVICELIST services have been started."
for service_name in `echo ${SERVICELIST}` ; do

   systemctl is-active $service_name >/dev/null
   if [ "$?" = "0" ] ; then
      echo "$service_name is running"
   else
      echo "$service_name is NOT running"
   fi
done

echo "$(date "+%Y %m %d %T %Z"): hostap config script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "hostap config FINISHED"
echo
