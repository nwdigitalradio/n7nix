#!/bin/bash
#
# Access point control program
#
# Script to start up host access point services
# The script enables & starts the services

scriptname="`basename $0`"
wifidev="wlan0"

FORCE_UPDATE=

SYSTEMD_DIR="/etc/systemd/system"
SYSTEMCTL="systemctl"

# Host access point service names
SERVICE_LIST="hostapd.service dnsmasq.service"
# Packages required by host access point
PKGLIST="hostapd dnsmasq iptables iptables-persistent iw"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# ===== function start_service

function start_service() {
    service="$1"
    echo "Starting service: $service"
    systemctl is-enabled "$service" > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "ENABLING $service"
        $SYSTEMCTL enable "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem ENABLING $service"
        fi
    fi
    $SYSTEMCTL --no-pager start "$service"
    if [ "$?" -ne 0 ] ; then
        echo "Problem starting $service"
    fi
}

# ===== function stop_service

function stop_service() {
    service="$1"
    systemctl is-enabled "$service" > /dev/null 2>&1
    if [ $? -eq 0 ] ; then
        echo "DISABLING $service"
        $SYSTEMCTL disable "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem DISABLING $service"
        fi
    else
        echo "Service: $service already disabled."
    fi
    $SYSTEMCTL stop "$service"
    if [ "$?" -ne 0 ] ; then
        echo "Problem STOPPING $service"
    fi
    echo "Service: $service now stopped."
}

# ===== function unitfile_update
# systemd unit file copy

function unitfile_update() {

    echo " == unit file update"
    echo " == systemd service files should be installed via package manager"
    return

    for unit_file in `echo "${SERVICE_LIST}"` ; do
        unitfile_${unit_file}
    done
    $SYSTEMCTL daemon-reload
}

# ===== function systemd unit file check
# systemd unit file exists check

function unitfile_check() {

    retcode=0
    for file in `echo "${SERVICE_LIST}"` ; do
        if [ ! -e "$SYSTEMD_DIR/${file}.service" ] ; then
            retcode=1
            echo "Systemd unit file: $SYSTEMD_DIR/${file}.service NOT found."
        else
            systemctl status $file >/dev/null 2>&1
            status=$?
            echo "Service: $file, status: $status"
        fi
    done
    if [ "$retcode" -eq 0 ] && [ -z "$FORCE_UPDATE" ] ; then
        echo "All access point systemd service files found"
    else
        unitfile_update
        retcode=1
    fi
    return $retcode
}

# ===== function check_ipforward

function check_ipforward() {
    ipf_status="ON"
    ipf="$(tr -d '\0' </proc/sys/net/ipv4/ip_forward)"
    if [ "$ipf" = "0" ] ; then
        ipf_status="OFF"
    fi
    echo "==== ipv4 packet forwarding is $ipf_status"
}

# ===== function check_packages
# check if required packages are installed

function check_packages() {

retcode=0
echo "==== Check if packages installed: $PKGLIST"

    for pkg_name in `echo ${PKGLIST}` ; do
        is_pkg_installed $pkg_name
        if [ $? -ne 0 ] ; then
            echo "$scriptname: Need to Install $pkg_name program"
            retcode=1
#           apt-get -qy install $pkg_name
        fi
    done
    return $retcode
}

# ===== function check_wpa_supp
function check_wpa_supp() {
    grep -si "network=" /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null 2>&1
    if [ $? -eq 0 ] ; then
        wpa_supp_status="OK"
    else
        wpa_supp_status="needs configuration"
    fi
    echo "WiFi wpa_supplicant $wpa_supp_status"
}

# ===== function status_service

function status_service() {
    service="$1"
    IS_ENABLED="ENABLED"
    IS_RUNNING="RUNNING"
    # echo "Checking service: $service"
    systemctl is-enabled "$service" > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        IS_ENABLED="NOT ENABLED"
    fi
    systemctl is-active "$service" > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        IS_RUNNING="NOT RUNNING"
    fi
}

# ===== device_status

device_status() {
    wifi_status=$(ip a show $wifidev | sed -n -e 's/^.*state //p' | cut -d' ' -f1)
    ipaddr2=$(ip a show $wifidev | grep "inet " | tr -s " " | cut -d ' ' -f3)
    ipaddr_str=
    if [ "$wifi_status" != "DOWN" ] ; then
        ipaddr_str=", with IP address of: $ipaddr2"
    fi
    echo "==== wifi device: $wifidev is $wifi_status$ipaddr_str"
}

# ===== ap_debugstatus
# For debugging a WiFi client connections

function ap_debugstatus() {
    echo "====  ${FUNCNAME[0]}"

    echo
    echo " === wpa_supplicant.conf"
    cat /etc/wpa_supplicant/wpa_supplicant.conf

    echo
    echo " === rfkill list"
    rfkill list all

    echo
    echo " === ifconfig"
    ip a show $wifidev

    #echo
    #echo " === lspci"
    #lspci
    echo
    echo " === lsusb"
    lsusb
    echo
    echo " === dmesg"
    dmesg | grep -i $wifidev
    echo
    echo " === iwconfig"
    iwconfig $wifidev
}

# ===== ap_status

function ap_status() {
    if [ ! -z $DEBUG ] ; then
        ap_debugstatus
        return
    fi
    for service in `echo ${SERVICE_LIST}` ; do
        status_service $service
        echo "Status for $service: $IS_RUNNING and $IS_ENABLED"
    done
}

# ===== function access point start
function ap_start() {
    if [ "$FORCE_UPDATE" = "true" ] ; then
        echo "DEBUG: Updating systemd unitfiles"
        unitfile_update
    fi
    for service in `echo "${SERVICE_LIST}"` ; do
        echo "Starting: $service"
        start_service $service
    done
}

# ===== function display_ip
# Display ip address of device
# First arg is device name

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

    ipaddr2=$(ip a show $device | grep "inet " | tr -s " " | cut -d ' ' -f3)
    retcode="$?"

    dbgecho "2 $ipaddr2, ret: $retcode"
    ipcmd="ip a show $device | grep \"inet \""
    if [[ "$retcode" == 0 ]] ; then
        echo "ipaddr2: $ipaddr2"
    else
        echo "ip a show failed with ret: $?"
        echo "Command: $ipcmd"
        (ip a show $device | grep "inet ")
    fi
}

# ===== function ap_stop
# Stop access point & bring up WiFi client

function ap_stop() {

    echo
    echo "  ${FUNCNAME[0]}"

    HOSTAPD_RUNNING=false
    service="hostapd"
    # Before doing anything determine if hostap is even running
    if systemctl is-active --quiet "$service" ; then
        HOSTAPD_RUNNING=true
    fi

    dbgecho "Set WiFi device down"
    sudo ip link set dev "$wifidev" down

    for service in `echo "${SERVICE_LIST}"` ; do
        if $SYSTEMCTL is-active --quiet "$service" ; then
            stop_service $service
        fi
    done

    # Start WiFi client
    dbgecho "Flush ip address"
    if $HOSTAPD_RUNNING ; then
        sudo ip addr flush dev "$wifidev"
    fi

    sudo ip link set dev "$wifidev" up

    if $HOSTAPD_RUNNING ; then
        sudo dhcpcd  -n "$wifidev" >/dev/null 2>&1
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
}

# ==== function display arguments used by this script

usage () {
	(
	echo "Usage: $scriptname [-f][-d][-h][status][stop][start][restart]"
        echo "                  No args will show status of access point daemons"
        echo "                  args with dashes must come before other arguments"
        echo "  start           start required access point processes"
        echo "  stop            stop all access point processes"
        echo "  status          display status of all access point processes"
        echo "  restart         stop access pint then restart"
        echo "  -f | --force    Update all systemd unit files"
        echo "  -d              Set DEBUG flag"
        echo "  -h              Display this message."
        echo
	) 1>&2
	exit 1
}

# ===== main

# Check if running as root
if [[ $EUID != 0 ]] ; then
   USER=$(whoami)
   SYSTEMCTL="sudo systemctl "
else
   echo "Should ONLY run as user NOT root"
   exit 1
fi

while [[ $# -gt 0 ]] ; do
APP_ARG="$1"

case $APP_ARG in
    -f|--force)
        FORCE_UPDATE=true
        echo "Force update mode on"
    ;;
    -d|--debug)
        DEBUG=1
        echo "Debug mode on"
    ;;
     -x)
        for service in `echo "${SERVICE_LIST}"` ; do
            diff ${SYSTEMD_DIR}/${service}.service systemd
        done
        exit 0
    ;;
    -h|--help|-?)
        usage
        exit 0
    ;;
    stop)
        ap_stop
        exit 0
    ;;
    start)
        ap_start
        exit 0
    ;;
    restart)
        ap_stop
        sleep  1
        ap_start
        exit 0
    ;;
    status)
        device_status
        check_wpa_supp
        ap_status
        check_ipforward
        check_packages
        echo "Finished access point status"
        exit 0
    ;;
    *)
        echo "Unrecognized command line argument: $APP_ARG"
        usage
        exit 0
    ;;
esac

shift # past argument
done

device_status
check_wpa_supp
ap_status
check_ipforward
check_packages
if [ $? -eq 0 ] ; then
    unitfile_check
fi

