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

# ===== function pa_status

function pa_status() {
    echo
    echo " == user status =="
    systemctl --no-pager --user status pulseaudio.service

    echo
    echo " == system status =="
    systemctl --no-pager --system status pulseaudio.service
}

# ===== function pa_stop

function pa_stop() {

    stop_service pulseaudio system
    SYSTEMCTL="systemctl"
    stop_service pulseaudio user

    systemctl --user stop pulseaudio.socket
    systemctl --user stop pulseaudio.service
    systemctl --user disable pulseaudio.socket
    systemctl --user disable pulseaudio.service
    systemctl --user mask pulseaudio.socket
    systemctl --user mask pulseaudio.service
}

# ===== function pa_stop

function pa_start() {

    SYSTEMCTL="systemctl"
#    start_service pulseaudio user

    systemctl --user unmask pulseaudio.socket
    systemctl --user unmask pulseaudio.service

    systemctl --user start pulseaudio.socket
    systemctl --user start pulseaudio.service

    systemctl --user enable pulseaudio.socket
    systemctl --user enable pulseaudio.service
}

# ==== function display arguments used by this script

usage () {
	(
	echo "Usage: $scriptname [-d][-h][status][stop][start][restart]"
        echo "  start           start required processes"
        echo "  stop            stop all processes"
        echo "  status          display status of PulseAudio"
        echo "  restart         stop PulseAudio then restart"
        echo "  -f | --force    Update all hostapd systemd unit files"
        echo "  -d              Set DEBUG flag"
        echo "  -h              Display this message."
        echo

	) 1>&2
	exit 1
}


# ===== main

# Check if running as root
if [[ $EUID != 0 ]] ; then
    SYSTEMCTL="sudo systemctl"
    USER=$(whoami)
    dbgecho "set sudo as user $USER"
fi

while [[ $# -gt 0 ]] ; do
APP_ARG="$1"

case $APP_ARG in
    -d|--debug)
        DEBUG=1
        echo "Debug mode on"
    ;;
    -h|--help|-?)
        usage
        exit 0
    ;;
    stop)
        pa_stop
        exit 0
    ;;
    start)
        pa_start
        exit 0
    ;;
    restart)
        pa_stop
        sleep  1
        pa_start
        exit 0
    ;;
    status)
        pa_status
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

pa_status
