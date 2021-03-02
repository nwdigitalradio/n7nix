#!/bin/bash
#
# Script to stop DRAWS manager systemd service
# The script disables & stops the service


USER=
SYSTEMCTL="systemctl"

SERVICE_LIST="draws-manager"

# ===== function start_service
function start_service() {
    service="$1"
    echo "Starting: $service"

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
}

# ===== main

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
    SYSTEMCTL="sudo systemctl"
    USER=$(whoami)
    dbgecho "set sudo as user $USER"
fi

# default to stop/disable draws-manager
if [[ $# -eq 0 ]] ; then
    for service in `echo ${SERVICE_LIST}` ; do
        # echo "DEBUG: Stopping service: $service"
        stop_service $service
    done
else
    # Any command line arguments then start draws-manager service
    start_service draws-manager
fi
