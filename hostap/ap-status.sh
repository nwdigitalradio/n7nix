#!/bin/bash
#
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

# ===== function is_pkg_installed

function is_pkg_installed() {
    dbgecho "Checking package: $1"
    return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# ===== function check_ipforward

function check_ipforward() {
    ipf_status="ON"
    ipf="$(tr -d '\0' </proc/sys/net/ipv4/ip_forward)"
    if [ "$ipf" = "0" ] ; then
        ipf_status="OFF"
    fi
    echo "ipv4 packet forwarding is $ipf_status"
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

# ===== function hostap_status

function hostap_status() {

    for service in `echo ${SERVICE_LIST}` ; do
        status_service $service
        echo "Status for $service: $IS_RUNNING and $IS_ENABLED"
    done
}

# ===== function hostap_debugstatus

function hostap_debugstatus() {

    echo "Test if $SERVICE_LIST services have been started."
    for service_name in `echo ${SERVICE_LIST}` ; do
        echo
        echo "== status $service_name services =="
        if systemctl is-active --quiet $service_name ; then
            echo "$service_name is running"
        else
            echo "$service_name is NOT running"
        fi
        systemctl --no-pager status $service_name
    done
}

# ===== main

# For dnsmasq version 2.77 and above ok
# otherwise remove dns-root-data package
pkg_name="dns-root-data"
is_pkg_installed $pkg_name
if [ $? -eq 0 ] ; then
    echo "Package $pkg_name IS installed, removing package"
#   sudo apt-get remove -y -q $pkg_name
fi
dnsmasq_ver=$(dnsmasq --version | cut -d' ' -f3 | head -n1)
echo "Running dnsmasq version: $dnsmasq_ver, Version 2.77 is ok"

while [[ $# -gt 0 ]] ; do

    key="$1"
    case $key in
        -d)
            echo "hostap Debug Status"
            hostap_debugstatus
            check_ipforward
            exit 0
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

hostap_status
check_ipforward

