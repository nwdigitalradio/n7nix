#!/bin/bash
#
# Script to stop WiFi access point & start WiFi client
# The script disables and stops services
DEBUG=

# WiFi device name to use. Default is wlan0.
wifidev="wlan0"

SERVICE_LIST="hostapd dnsmasq"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function usage

# Display program help info

function usage () {
	(
	echo "Usage: $scriptname [-d][-h]"
        echo "    -d switch to turn on verbose debug display"
        echo "    -h display this message."
	echo " exiting ..."
	) 1>&2
	exit 1
}

# ===== function stop_service

function stop_service() {
    service="$1"
    # Does the service file exist?
    if systemctl list-units --full --all | grep -Fq $service  ; then
        # Is the service enabled?
        if systemctl is-enabled --quiet "$service" ; then
            echo "DISABLING $service"
            systemctl disable "$service"
            if [ "$?" -ne 0 ] ; then
                echo "Problem DISABLING $service"
            fi
        else
            echo "Service: $service already disabled."
        fi
        # Is the service running?
        if systemctl is-active --quiet "$service" ; then
            systemctl stop "$service"
            if [ "$?" -ne 0 ] ; then
                echo "Problem stopping $service"
            fi
        else
            echo "Service: $service NOT running"
        fi
    else
        echo "Service $service NOT installed"
    fi
}

# ===== function display_ip
# Display ip address

function display_ip() {
    device="$1"
    dbgecho "Display ip address"

    ipaddr1=$(ifconfig $device | grep "inet " | tr -s " " | cut -d ' ' -f3)
    retcode="$?"

    dbgecho "1 $ipaddr1, ret: $retcode"
    ipcmd="ifconfig $device \| grep \"inet \""
    if [[ "$retcode" == 0 ]] ; then
        echo "ipaddr1: $ipaddr1"
    else
        echo "ifconfig failed with ret: $?"
        echo "Command: $ipcmd"
        (ifconfig $device | grep "inet ")
    fi

    ipaddr2=$(ip a show wlan0 | grep "inet " | tr -s " " | cut -d ' ' -f3)
    retcode="$?"

    dbgecho "2 $ipaddr2, ret: $retcode"
    ipcmd="ip a show $device | grep \"inet \""
    if [[ "$retcode" == 0 ]] ; then
        echo "ipaddr2: $ipaddr2"
    else
        echo "ip a show failed with ret: $?"
        echo "Command: $ipcmd"
        (ip a show $wifidev | grep "inet ")
    fi
}
# ===== main

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root"
   exit 1
fi

while [[ $# -gt 0 ]] ; do

    key="$1"
    case $key in
        -d)
            echo "hostap Debug Status"
            DEBUG=1
        ;;
        -h)
            usage
            exit 0
        ;;
        *)
            echo "Undefined argument: $key"
            usage
            exit 1
        ;;
    esac
    shift # past argument or value
done

HOSTAPD_RUNNING=false

# Before doing anything determine if hostap is even running
if systemctl is-active --quiet "$service" ; then
    HOSTAPD_RUNNING=true
fi

dbgecho "Set WiFi device down"
ip link set dev "$wifidev" down

for service in `echo ${SERVICE_LIST}` ; do
#    echo "DEBUG: Stopping service: $service"
    stop_service $service
done

# Start WiFi client
dbgecho "Flush ip address"
if $HOSTAPD_RUNNING ; then
    ip addr flush dev "$wifidev"
fi

ip link set dev "$wifidev" up

if $HOSTAPD_RUNNING ; then
    dhcpcd  -n "$wifidev" >/dev/null 2>&1
fi

echo "wait for ip address to be set"
start_sec=$SECONDS
while ! ifconfig $wifidev | grep "inet " > /dev/null 2>&1 ; do
#   echo -n "."
    :
done
echo "Loop ran for $((SECONDS-start_sec)) seconds"
display_ip $wifidev

#ifconfig $wifidev | grep "inet "
#ip a show wlan0
