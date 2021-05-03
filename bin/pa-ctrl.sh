#!/bin/bash
#
# pa-ctrl.sh
#
# stop and disable pulseaudio for both system & user services.

scriptname="`basename $0`"
DEBUG=
QUIET=
USER=

SYSTEMCTL="systemctl"

# if DEBUG is defined then echo
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }
# if QUIET is defined the DO NOT echo
function quietecho { if [ -z "$QUIET" ] ; then echo "$*"; fi }

# ===== function stop_service

function stop_service() {
    service="$1"
    scope="$2"
    systemctl --$scope is-enabled "$service" > /dev/null 2>&1
    if [ $? -eq 0 ] ; then
        quietecho "DISABLING $service"
        $SYSTEMCTL --$scope disable "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem DISABLING $service"
        fi
    else
        echo "Service: $scope $service already disabled."
    fi

    systemctl --$scope is-active --quiet "$service"
    if [ $? -eq 0 ] ; then
        export XDG_RUNTIME_DIR="/run/user/$UID"
        export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
        $SYSTEMCTL --$scope stop "${service}.socket"
        if [ "$?" -ne 0 ] ; then
            echo "Problem STOPPING $scope ${service}.socket"
        fi
        $SYSTEMCTL --$scope stop "${service}.service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem STOPPING $scope ${service}.service"
        fi
#        $SYSTEMCTL --$scope mask ${service}.socket
#        $SYSTEMCTL --$scope mask ${service}.service
    else
        echo "Service: $scope $service is already stopped"
    fi
}

# ===== main

# Check if running as root
if [[ $EUID != 0 ]] ; then
    SYSTEMCTL="sudo systemctl"
    USER=$(whoami)
    dbgecho "set sudo as user $USER"
fi

stop_service pulseaudio system
SYSTEMCTL="systemctl"
stop_service pulseaudio user

echo
echo " == user status =="
systemctl --no-pager --user status pulseaudio.service

echo
echo " == system status =="
systemctl --no-pager --system status pulseaudio.service
