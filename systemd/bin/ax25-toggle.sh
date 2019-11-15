#!/bin/bash
#
DEBUG=
scriptname="`basename $0`"

SYSTEMCTL="sudo systemctl"
DESKTOP_FILE="/home/pi/Desktop/ax25-startstop.desktop"
SERVICE_LIST="direwolf.service ax25dev.path ax25dev.service ax25-mheardd.service ax25d.service"
LOG_DIR="/home/pi/log"
LOG_FILE="$LOG_DIR/ax25-startstop.log"
LOG_OUTPUT="$LOG_FILE"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function Display program usage info
#
usage () {
	(
	echo "Usage: $scriptname [-d][-h]"
        echo "   -d  debug  turn on debug output"
        echo "   -h  help   display this message"
        ) 1>&2
        exit 1
}

# ===== function stop_service

function stop_service() {
    service="$1"
    $SYSTEMCTL is-enabled "$service" > /dev/null 2>&1
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

# ===== function start_service

function start_service() {
    service="$1"
    $SYSTEMCTL is-enabled "$service" > /dev/null 2>&1
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

# ===== main

# Check if running as root
if [[ $EUID != 0 ]] ; then
   SYSTEMCTL="sudo systemctl "
else
   SYSTEMCTL="systemctl"
fi

# Check for any command line arguments
if [[ $# -gt 0 ]] ; then

    key="$1"

    case $key in
        -d)
            echo "Turn on debug"
            DEBUG=1
        ;;
        -h)
            usage
            exit 1
        ;;
        *)
            echo "Undefined argument: $key"
            usage
            exit 1
        ;;
    esac
fi

if [ ! -z "$DEBUG" ] ; then
    if [ ! -d "$LOG_DIR" ] ; then
        mkdir -p "$LOG_DIR"
    fi
   LOG_OUTPUT="$LOG_FILE"
else
#   LOG_OUTPUT="/dev/null 2>&1"
   LOG_OUTPUT="/dev/null"
   SYSTEMCTL="$SYSTEMCTL --quiet"
fi

# echo "output redirected to: $LOG_OUTPUT"

# run in a sub shell
(
# Check if direwolf is already running.
pid=$(pidof direwolf)
if [ $? -eq 0 ] ; then
    echo "== Direwolf is running pid of $pid, will stop"
    # toggle ax25 & direwolf OFF

    for service in `echo ${SERVICE_LIST}` ; do
        echo "Stopping: $service"
        stop_service $service
    done

    # change icon to be on
    echo "changed icon to ON"
    cp /home/pi/bin/ax25-start.desktop /home/pi/Desktop/ax25-startstop.desktop
    # sed leaves temporary file artifacts on desktop
#    sed -i -e "/Icon=/ s/_off/_on/" "$DESKTOP_FILE" > /dev/null
#    sed -i -e "/Name=/ s/25-stop/25-start/" "$DESKTOP_FILE" > /dev/null
    echo
else
    # toggle ax25 & direwolf ON
    echo "== Starting Direwolf & AX.25"
    for service in `echo ${SERVICE_LIST}` ; do
        echo "Starting: $service"
        start_service $service
    done

    # change icon to be off
    echo "changed icon to OFF"
    cp /home/pi/bin/ax25-stop.desktop /home/pi/Desktop/ax25-startstop.desktop
    # sed leaves temporary file artifacts on desktop
#    sed -i -e "/Icon=/ s/_on/_off/" "$DESKTOP_FILE" > /dev/null
#    sed -i -e "/Name=/ s/25-start/25-stop/" "$DESKTOP_FILE" > /dev/null
    echo
fi
) >> "$LOG_OUTPUT"

if [ ! -z "$DEBUG" ] ; then
    echo -n "Verify icon name: "
    grep "Icon" /home/pi/Desktop/ax25-startstop.desktop
fi
