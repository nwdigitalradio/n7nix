#!/bin/bash

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
PKGLIST="iptables iptables-persistent"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# ===== main
echo "setup iptables"

# check if packages are installed
dbgecho "Check packages: $PKGLIST"

# Fix for iptables-persistent broken
#  https://discourse.osmc.tv/t/failed-to-start-load-kernel-modules/3163/14
#  https://www.raspberrypi.org/forums/viewtopic.php?f=63&t=174648

sed -i -e 's/^#*/#/' /etc/modules-load.d/cups-filters.conf

for pkg_name in `echo ${PKGLIST}` ; do

   is_pkg_installed $pkg_name
   if [ $? -ne 0 ] ; then
      echo "$scriptname: Need to Install $pkg_name program"
      apt-get -qy install $pkg_name
   fi
done

# echo "add iptables-restore to rc.local"
# or use iptables-persistent
CREATE_IPTABLES=false
IPTABLES_FILES="/etc/iptables/rules.ipv4.ax25 /lib/dhcpcd/dhcpcd-hooks/70-ipv4.ax25"
for ipt_file in `echo ${IPTABLES_FILES}` ; do

   if [ -f $ipt_file ] ; then
      echo "iptables file: $ipt_file exists"
   else
      echo "Need to create iptables file: $ipt_file"
      CREATE_IPTABLES=true
   fi
done

if [ "$CREATE_IPTABLES" = "true" ] ; then
   iptables -A OUTPUT -o ax0 -d 224.0.0.22 -p igmp -j DROP
   iptables -A OUTPUT -o ax0 -d 224.0.0.251 -p udp -m udp --dport 5353 -j DROP
   iptables -A OUTPUT -o ax1 -d 224.0.0.22 -p igmp -j DROP
   iptables -A OUTPUT -o ax1 -d 224.0.0.251 -p udp -m udp --dport 5353 -j DROP
   sh -c "iptables-save > /etc/iptables/rules.ipv4.ax25"

   cat  > /lib/dhcpcd/dhcpcd-hooks/70-ipv4.ax25 <<EOF
iptables-restore < /etc/iptables/rules.ipv4.ax25
EOF

fi

echo "$(date "+%Y %m %d %T %Z"): $scriptname: iptables install/config script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "iptables install/config FINISHED"
echo
