#! /bin/bash
#
# Set a fixed ip address
#
# Edit files:
#  /etc/network/interfaces
#  /etc/dhcpcd.conf

lan_ipaddr="10.0.42.91"
lan_router="10.0.42.1"

wlan_ipaddr="10.0.44.1"

cat <<EOT > /etc/network/interfaces
source-directory /etc/network/interfaces.d

auto lo
iface lo inet loopback

iface eth0 inet manual

allow-hotplug wlan0
iface wlan0 inet static
  address $wlan_ipaddr
  netmask 255.255.255.0
  network 10.0.44.0
  broadcast 10.0.44.255
EOT

cat <<EOT >> /etc/dhcpcd.conf

interface eth0

  static ip_address=$lan_ipaddr/24
  static routers=$lan_router
  static domain_name_servers=$lan_router

interface wlan0

  static ip_address=$wlan_ipaddr/24
EOT
echo "You are about to lose your SSH session"
echo "Login in using lan address: $lan_ipaddr or wlan address: $wlan_ipaddr"
systemctl is-enabled NetworkManager.service
if [ $? -eq 0 ] ; then
  systemctl disable NetworkManager.service
fi
systemctl daemon-reload
systemctl restart dhcpcd.service
service networking restart

echo
echo "Fixed IP address config FINISHED"
echo
