#!/bin/bash
#
# Install a host access point
#
# hosts, resolv.conf /etc/network/interfaces /etc/dhcpcd.conf
#
# == Configure hostapd.conf
# == Check dnsmasq Version number
# == Configure dnsmasq
# == set up IPV4 forwarding
# == setup iptables
# == Give WiFi device a fixed IP address
# == start services: hostapd, dnsmasq

DEBUG=1
# Set this to 'true' to input a console address
INPUT_IPADDR=false

scriptname="`basename $0`"
# WiFi device name
wifidev="wlan0"

DNSMASQ_CFG_FILE="/etc/dnsmasq.conf"
fixed_ip_address="10.0.40.4"
ip_root=${fixed_ip_address%.*}

UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
SSID="NOT_SET"
SERVICELIST="hostapd.service dnsmasq.service"

# ===== function debugecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function version_gt
function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

# ===== function is_pkg_installed
function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# ===== function determine if RPi version has WiFi
function get_has_WiFi() {
# Initialize product ID
HAS_WIFI=
prgram="piver.sh"
which $prgram
if [ "$?" -eq 0 ] ; then
   dbgecho "Found $prgram in path"
   $prgram > /dev/null 2>&1
   HAS_WIFI=$?
else
   currentdir=$(pwd)
   # Get path one level down
   pathdn1=$( echo ${currentdir%/*})
   dbgecho "Test pwd: $currentdir, path: $pathdn1"
   if [ -e "$pathdn1/bin/$prgram" ] ; then
       dbgecho "Found $prgram here: $pathdn1/bin OK"
       $pathdn1/bin/$prgram > /dev/null 2>&1
       HAS_WIFI=$?
   else
       echo "Could not locate $prgram (ERROR) default to no WiFi found"
       HAS_WIFI=0
   fi
fi
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
function valid_ip() {
    local  ip=$1
    local  stat=1

    dbgecho "Verifying ip address: $ip"

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    dbgecho "Verifying ip address ret: $stat"
    return $stat
}

# ===== function get_ipaddr

function get_ipaddr() {

    wifi_intface=$1
    retcode=1
    ip_addr=
    # clear the read buffer
    read -t 1 -n 10000 discard

    echo -n "Enter ip address for WiFi interface $wifi_intface followed by [enter]"

    # -p display PROMPT without a trailing new line
    # -e readline is used to obtain the line
    read -ep ": " ip_addr

    if [ ! -z "$ip_addr" ] ; then

        count_dots=$(grep -o "\." <<< "$ip_addr" | wc -l)
        if (( count_dots != 3 )) ; then
            dbgecho "Error: Wrong number of dots in ipaddr: $ip_addr $count_dots"
            return 1
        fi
        valid_ip $ip_addr
        retcode=$?
        if [ $retcode -eq 1 ] ; then
            echo "INVALID IP address: $ip_addr"
            retcode=1
        else
            echo "Valid ip address: $ip_addr"
            retcode=0
        fi
    else
        # Return code for no ip address inputted.
        retcode=0
    fi
    return $retcode
}

# ===== function copy_dnsmasq
function copy_dnsmasq() {

    echo "DEBUG: copy_dnsmasq arg: $1"
    if [ -z "$1" ] ; then
        echo "$scriptname: function copy_dnsmasq() needs an argument ... exiting"
        exit 1
    fi

    # Add to end of file
    sudo tee "$DNSMASQ_CFG_FILE" > /dev/null << EOT
interface=$wifidev # Listening interface
dhcp-range=${ip_root}.100,${ip_root}.200,255.255.255.0,24h
                # Pool of IP addresses served via DHCP
domain=wlan     # Local wireless DNS domain
address=/rpi.wlan/$fixed_ip_address
                # Alias for this router
EOT

    # Disable this config
    if [ 1 -eq 0 ] ; then

    # Create a new file
    sudo tee $1/dnsmasq.conf > /dev/null << EOT
interface=$wifidev   # Use WiFi interface $wifidev
dhcp-range=${ip_root}.201,${ip_root}.239,12h
listen-address=$fixed_ip_address
bind-interfaces      # Bind to the interface to be sure we aren't sending things elsewhere
server=1.1.1.1       # Forward DNS requests to CloudFare
domain-needed        # Don't forward short names
bogus-priv           # Never forward addresses in the non-routed address spaces.

EOT

    fi
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

    sudo tee $1/hostapd.conf > /dev/null <<EOT
country_code=US
interface=$wifidev
ssid=snout
hw_mode=g
channel=7
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
#wpa=2
#wpa_passphrase=AardvarkBadgerHedgehog
#wpa_key_mgmt=WPA-PSK
#wpa_pairwise=TKIP
#rsn_pairwise=CCMP
EOT

# Disable this config
if [ 1 -eq 0 ] ; then
    sudo tee $1/hostapd.conf > /dev/null <<EOT
interface=$wifidev

# Use the nl80211 driver with the brcmfmac driver
driver=nl80211

# This is the name of the network
ssid=$SSID

# Use the 2.4GHz band
hw_mode=g

# Use channel 7
channel=7

# Enable 802.11n
# Set proper Country Code
country_code=US
ieee80211n=1
ieee80211d=1

# Enable WMM
wmm_enabled=1

# Enable 40MHz channels with 20ns guard interval
ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]

# Accept all MAC addresses
macaddr_acl=0

# Require clients to know the network name
#ignore_broadcast_ssid=0

## Authentication begin
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

fi
}

# ===== function seq_backup
# Backup previous configuration file with a sequential name
# ie. never destroy a backup file
# arg 1 is path/root configuration file name

function seq_backup() {
    rootfname=$1
    today="$( date +"%Y%m%d" )"
    number=0
    # -- in printf statement: whatever follows should not be interpreted
    #    as a command line option to printf
    suffix="$( printf -- '-%02d' "$number" )"

    while test -e "$rootfname-$today$suffix.conf"; do
        (( ++number ))
        suffix="$( printf -- '-%02d' "$number" )"
    done

    fname="$rootfname-$today$suffix.conf"
    mv ${rootfname}.conf $fname
}


# ===== function dnsmasq_config
function dnsmasq_config() {

    # Check if a previous dnsmasq configuration file exists
    if [ -f "$DNSMASQ_CFG_FILE" ] ; then
        dnsmasq_linecnt=$(wc -l $DNSMASQ_CFG_FILE)
        # get rid of everything except line count
        dnsmasq_linecnt=${dnsmasq_linecnt%% *}
        dbgecho "dnsmasq.conf line count: $dnsmasq_linecnt"
        if (("$dnsmasq_linecnt" > "10")) ; then
            seq_backup "/etc/dnsmasq"
            echo "Original dnsmasq config file saved as $fname"
        fi
    fi

    # Previous dnsmasq config file should be saved at this point and there
    # should be no config file

    # Check if there is no dnsmasq config file
    if [ ! -f "$DNSMASQ_CFG_FILE" ] ; then
        copy_dnsmasq "/etc"
    else
        echo "/etc/dnsmasq.conf already exists."
        copy_dnsmasq "/tmp"

        echo "=== diff of current dnsmasq config ==="
        diff -b "$DNSMASQ_CFG_FILE" /tmp
        echo "=== end diff ==="
    fi
}

# ===== hostapd_config
function hostapd_config() {
    echo "Copy hostap config file."
    if [ ! -f /etc/hostapd/hostapd.conf ] ; then
        copy_hostapd "/etc/hostapd"
    else
        echo "/etc/hostapd/hostapd.conf already exists."
        seq_backup "/etc/hostapd/hostapd"
        copy_hostapd "/tmp"
        echo "=== diff of current hostapd config ==="
        diff -b /etc/hostapd/hostapd.conf /tmp
        echo "=== end diff ==="
    fi
}

# ===== function start_service
function start_service() {
    service="$1"
    systemctl is-enabled "$service" > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "ENABLING $service"
        sudo systemctl enable "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem ENABLING $service"
        fi
    fi
    sudo systemctl --no-pager start "$service"
    if [ "$?" -ne 0 ] ; then
        echo "Problem starting $service"
    fi
}


# ===== main

echo " == Config hostap on an RPi 3/4"

# Be sure we are NOT running as root
if [[ $EUID = 0 ]] ; then
   echo "Must NOT be root."
   exit 1
fi

# Verify that RPi has built-in WiFi
get_has_WiFi
if [ $? -ne "0" ] ; then
   echo "No WiFi found ... exiting"
   exit 1
fi

dbgecho "== Found WiFi"

echo "== Configuring: hostapd.conf"
hostapd_config

echo "Edit existing default config file to point to new config file."
# edit default hostapd config to use new config file
sudo sed -i 's;\#DAEMON_CONF="";DAEMON_CONF="/etc/hostapd/hostapd.conf";' /etc/default/hostapd

# Check dnsmasq version number for dns-root-data problem
# Dnsmasq bug: in versions below 2.77 there is a recent bug that may
# cause the hotspot not to start for some users. This can be resolved by
# removing the dns-root-data.

echo "== Check dnsmasq Version number"
current_dnsmasq_ver=$(dnsmasq --version | head -n1 | cut -d ' ' -f3)
echo "Configuring: dnsmasq, running version: $current_dnsmasq_ver"

check_dnsmasq_ver="2.77"

if [ "$current_dnsmasq_ver" = "$check_dnsmasq_ver" ] ; then
    echo "dnsmasq version is identical to check version: $check_dnsmasq_ver, OK"
else
    if version_gt $current_dnsmasq_ver $check_dnsmasq_ver ; then
        echo "Current dnsmasq version is greater than check version($check_dnsmasq_ver), OK"
    else
        pkg_name="dns-root-data"
        echo "Current dnsmasq version is less than check version($check_dnsmasq_ver), removing package dns-root-data"
        is_pkg_installed $pkg_name
        if [ $? -eq 0 ] ; then
            echo "$scriptname: Will purge $pkg_name program"
            sudo apt-get purge dns-root-data
        fi
    fi
fi

echo "== Configure dnsmasq"
dnsmasq_config

# set up IPV4 forwarding
echo "== Set IPV4 forwarding"
#ipf=$(cat /proc/sys/net/ipv4/ip_forward)
ipf="$(tr -d '\0' </proc/sys/net/ipv4/ip_forward)"

echo "ip_forward is $ipf"
if [ "$ipf" = "0" ] ; then
   sudo  sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
fi

sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

echo "== setup iptables"
#echo "add iptables-restore to rc.local"
# or use iptables-persistent
CREATE_IPTABLES=false
IPTABLES_FILES="/etc/iptables/rules.ipv4.nat /lib/dhcpcd/dhcpcd-hooks/70-ipv4.nat"
for ipt_file in `echo ${IPTABLES_FILES}` ; do

   if [ -f $ipt_file ] ; then
      echo "iptables file: $ipt_file exists"
   else
      echo "Need to create iptables file: $ipt_file"
      CREATE_IPTABLES=true
   fi
done

if [ "$CREATE_IPTABLES" = "true" ] ; then
   sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
   sudo iptables -A FORWARD -i eth0 -o $wifidev -m state --state RELATED,ESTABLISHED -j ACCEPT
   sudo iptables -A FORWARD -i $wifidev -o eth0 -j ACCEPT
   sudo sh -c "iptables-save > /etc/iptables/rules.ipv4.nat"

   sudo iptables -t nat -S
   sudo iptables -S
   sudo tee /lib/dhcpcd/dhcpcd-hooks/70-ipv4.nat > /dev/null << EOF
iptables-restore < /etc/iptables/rules.ipv4.nat
EOF

fi

##############################
### Install a fixed IP address
##############################

echo "== Give WiFi device a fixed IP address"

if [ "$INPUT_IPADDR" = "true" ] ; then
    # Prompt for a WiFi IP address
    echo "Current WiFi ip addresses:  $fixed_ip_address"
    echo "If you do not understand or care about the following just hit enter for default values"

    # Input IP address for WiFi from console
    while  ! get_ipaddr $wifidev ; do
        echo "Input error, try again"
    done
    if [ ! -z "$ip_addr" ] ; then
        fixed_ip_address="$ip_addr"
        ip_root=${fixed_ip_address%.*}
        echo "Setting $wifidev ip address to: $fixed_ip_address, ip address root to: $ip_root"
    fi
else
    # Derive an IP address from LAN network address
    currentdir=$(pwd)
    prgram="fixed_ip.sh"
    if [ -e "$currentdir/$prgram" ] ; then
        dbgecho "Found $prgram here: $currentdir OK"
        ./$currentdir/$prgram -w $fixed_ip_address > /dev/null 2>&1
    fi
fi

# May need to unmask hostapd first
#sudo systemctl unmask hostapd
#sudo systemctl enable hostapd
#sudo systemctl start hostapd

echo "== start systemd services"
sudo systemctl daemon-reload
for service in `echo ${SERVICELIST}` ; do
    echo "Starting: $service"
    start_service $service
done

echo
echo "Test if services: $SERVICELIST have been started."
for service_name in `echo ${SERVICELIST}` ; do

   if systemctl is-active --quiet $service_name ; then
      echo "$service_name is running"
   else
      echo "$service_name is NOT running"
   fi
done

echo "$(tput setaf 1) === NEED to REBOOT ===$(tput sgr0)"

echo "$(date "+%Y %m %d %T %Z"): $scriptname: hostap config script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "hostap config FINISHED"
echo
