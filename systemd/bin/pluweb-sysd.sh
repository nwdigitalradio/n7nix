#!/bin/bash
#
# Control systemd service with arguments:
#  start, stop, status
#

# Uncomment this statement for debug echos
# DEBUG=1

service="pluweb"
scriptname="`basename $0`"
CTRL_CHOICES="start stop status"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function root_chk
# Check if running as root and exit if not

function root_chk() {
    # Be sure we're running as root
    if [[ $EUID != 0 ]] ; then
        echo "Must be root"
        exit 1
    fi
}

# ===== function service_start

function service_start() {
    root_chk

    type -P nodejs &>/dev/null
    if [ "$?" -ne 0 ] ; then
        echo "node.js is NOT installed."
        exit 1
    fi

    systemctl is-enabled "$service" > /dev/null 2>&1
    if [ "$?" -ne 0 ] ; then
        echo "ENABLING $service"
        systemctl enable "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem ENABLING $service"
        fi
    else
        dbgecho "Service $service already enabled"
    fi

    if systemctl is-active --quiet $service ; then
        echo "$service is already running."
    else
        systemctl --no-pager start $service.service
        if [ "$?" -ne 0 ] ; then
            echo "Problem starting $service"
        fi
    fi
}

# ===== function service_stop

function service_stop() {
    root_chk

    if systemctl is-active --quiet $service ; then
        systemctl stop $service.service
        if [ "$?" -ne 0 ] ; then
            echo "Problem stopping $service"
        fi
    else
        echo "$service is NOT running."
    fi

    systemctl is-enabled "$service" > /dev/null 2>&1
    if [ "$?" -ne 0 ] ; then
        echo "$service is NOT enabled"
    else
        systemctl disable $service.service
    fi
}

# ===== function service_status

function service_status() {
    echo "Systemd $service.service is $(systemctl is-enabled $service.service)"
    systemctl --no-pager status $service.service
}

# ===== main

dbgecho "$scriptname: systemd control"

# Default to running status
CTRL_SELECT="status"

# Check if there are any args on command line
if (( $# != 0 )) ; then
   CTRL_SELECT=$1
else
   dbgecho "No control action chosen with command arg, running status"
fi

case $CTRL_SELECT in
    start)
        service_start
    ;;
    stop)
        service_stop
    ;;
    status)
        service_status
        journalctl --no-pager -u $service.service | tail -n 20
    ;;
   *)
      echo "$(date "+%Y %m %d %T %Z"): $scriptname: Undefined control, must be one of $CTRL_CHOICES"
      exit 1
   ;;
esac
