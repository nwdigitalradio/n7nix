#!/bin/bash
#
# Change IP addresses of two AX.25 interfaces
# To take affect must either stop start ax.25 or reboot
#
# Uncomment this statement for debug echos
#DEBUG=1

scriptname="`basename $0`"
ax25upd_filename="/etc/ax25/ax25-upd"


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

    ax25_intface=$1
    retcode=1
    ip_addr=
    # clear the read buffer
    read -t 1 -n 10000 discard

    echo -n "Enter ip address for AX.25 interface $ax25_intface followed by [enter]"

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

# ===== function change_ax25_ip
# If the IP addresses have already been changed prompt for changing them back
# to default addresses

function change_ax25_ip() {

# Reference:
#  https://www.febo.com/packet/linux-ax25/ax25-config.html
# Default addresses
dummy_ipaddress_0="192.168.255.2"
dummy_ipaddress_1="192.168.255.3"

ipaddr_ax0=$(grep -i "IPADDR_AX0=" "$ax25upd_filename" | cut -d'=' -f2)
#Remove surronding quotes
ipaddr_ax0="${ipaddr_ax0%\"}"
ipaddr_ax0="${ipaddr_ax0#\"}"
cur_ipaddr_ax0="$ipaddr_ax0"

ipaddr_ax1=$(grep -i "IPADDR_AX1=" "$ax25upd_filename" | cut -d'=' -f2)
#Remove surronding quotes
ipaddr_ax1="${ipaddr_ax1%\"}"
ipaddr_ax1="${ipaddr_ax1#\"}"
cur_ipaddr_ax1="$ipaddr_ax1"

echo "Current AX.25 ip addresses: ax0: $ipaddr_ax0, ax1: $ipaddr_ax1"

if [ "$ipaddr_ax0" = "$dummy_ipaddress_0" ] && [ "$ipaddr_ax1" = "$dummy_ipaddress_1" ] ; then
    dbgecho "AX.25 ip addresses are original default addresses"
else
    read -p "AX.25 addresses have already been modified, continue to change again (y or n)" -n 1 -r REPLY
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
        echo "IP addresses unchanged ..."
        return
    fi
fi

echo " hit enter for default values"

while  ! get_ipaddr ax0 ; do
    echo "Input error, try again"
done
if [ ! -z "$ip_addr" ] ; then
    echo "Setting ax0 to $ip_addr"
    ipaddr_ax0="$ip_addr"
else
    echo "ax0 using default: $ipaddr_ax0"
fi

while  ! get_ipaddr ax1 ; do
    echo "Input error, try again"
done
if [ ! -z "$ip_addr" ] ; then
    echo "Setting ax1 to $ip_addr"
    ipaddr_ax1="$ip_addr"
else
    echo "ax1 using default: $ipaddr_ax1"
fi

echo "AX.25 ip addresses: ax0: $ipaddr_ax0, ax1: $ipaddr_ax1"

dbgecho "== Check 1: current $ax25upd_filename on $(date)"
ls -alt $ax25upd_filename

# Are the current IP addresses same as input addresses?
# ie. no addresses were input
if [ "$ipaddr_ax0" = "$cur_ipaddr_ax0" ] && [ "$ipaddr_ax1" = "$cur_ipaddr_ax1" ] ; then
    echo "No change to AX.25 IP addresses"
else

    echo -e "\n\t$(tput setaf 4)before: $(tput setaf 7)\n"
    grep -i "IPADDR_AX.=" "$ax25upd_filename"

    # Replace everything after string IPADDR_AX0
    sed -i -e "/IPADDR_AX0/ s/^IPADDR_AX0=.*/IPADDR_AX0=\"$ipaddr_ax0\"/"  $ax25upd_filename
    if [ "$?" -ne 0 ] ; then
        echo -e "\n\t$(tput setaf 1)Failed to change ax0 ip address $(tput setaf 7)\n"
    fi

    # Replace everything after string IPADDR_AX1
    sed -i -e "/IPADDR_AX1/ s/^IPADDR_AX1=.*/IPADDR_AX1=\"$ipaddr_ax1\"/"  $ax25upd_filename
    if [ "$?" -ne 0 ] ; then
        echo -e "\n\t$(tput setaf 1)Failed to change ax1 ip address $(tput setaf 7)\n"
    fi
fi

echo -e "\n\t$(tput setaf 4)after: $(tput setaf 7)\n"
grep -i "IPADDR_AX.=" $ax25upd_filename

dbgecho "== Check 2: Verify $ax25upd_filename on $(date)"
if [ ! -z "$DEBUG" ] ; then
    head -n 20 $ax25upd_filename
    ls -alt $ax25upd_filename
fi
}

# ===== main

echo "=== Set ip addresses on AX.25 interfaces"
# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root"
   exit 1
fi

# Insert the two ip addresses into the ax25-upd script

change_ax25_ip

echo "=== FINISHED Setting up ip addresses for AX.25 interfaces"
