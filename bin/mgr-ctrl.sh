#!/bin/bash
#
# Script to stop DRAWS manager systemd service
# The script disables & stops the service

DEBUG=
USER=
SYSTEMCTL="systemctl"
SERVICE_LIST="draws-manager"
scriptname="`basename $0`"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

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
    systemctl --no-pager status $service
}

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

function mgr_stop() {

    for service in `echo ${SERVICE_LIST}` ; do
        dbgecho "DEBUG: Stopping service: $service"
        stop_service $service
    done
}

function mgr_status() {
    for service in `echo ${SERVICE_LIST}` ; do
        status_service $service
	echo
        echo " Status for $service: $IS_RUNNING and $IS_ENABLED"
    done
}

# ===== function usage
# Display program help info

function usage () {
	(
	echo "Usage: $scriptname [start][stop][status][-h]"
        echo "                No args will show status of draws-manager"
        echo "   start        start required manager processes"
        echo "   stop         stop all manager processes"
        echo "   status       display status of manager processes"
        echo "   -h           display this message."
	echo " exiting ..."
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
        stop)
            mgr_stop
            exit 0
        ;;
        start)
            start_service draws-manager
	    exit 0
        ;;
        status)
            mgr_status
	    exit 0
        ;;
        -h|--help|-?)
            usage
            exit 0
        ;;
        *)
            echo "Undefined argument: $key"
            usage
            exit 1
        ;;
    esac
    shift # past argument
done

mgr_status
