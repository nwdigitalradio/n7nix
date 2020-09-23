#!/bin/bash
#
# tracker control program
#
# This script controls 3 processes using systemd service files and
# using screen

scriptname="`basename $0`"

TRACKER_CFG_DIR="/etc/tracker"
TRACKER_CFG_FILE="$TRACKER_CFG_DIR/aprs_tracker.ini"
SYSTEMD_DIR="/etc/systemd/system"
SYSTEMCTL="systemctl"

# There is a single screen service which started the other 3 services
# SERVICE_NAMES="tracker.service"

# Systemd service names
SERVICE_NAMES="aprs-server tracker-webserver plu-webserver"


function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

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

# ===== function unitfile_aprs-server

function unitfile_aprs-server() {
    sudo tee ${SYSTEMD_DIR}/aprs-server.service > /dev/null << EOT
[Unit]
Description=aprs_tracker
BindsTo=sys-subsystem-net-devices-ax0.device
After=network.service
After=ax25dev.service
After=sys-subsystem-net-devices-ax0.device

[Service]
ExecStart=/bin/bash -c '/usr/local/bin/aprs -c /etc/tracker/aprs_tracker.ini'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOT

}

# ===== function unitfile_tracker-webserver

function unitfile_tracker-webserver() {
    sudo tee ${SYSTEMD_DIR}/tracker-webserver.service > /dev/null << EOT
[Unit]
Description=tracker_webserver
After=network.service
After=ax25dev.service
After=aprs-server.target

[Service]
ExecStart=/bin/bash -c '/usr/bin/nodejs /home/$USER/bin/webapp/tracker-server.js /etc/tracker/aprs_tracker.ini'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOT
}

# ===== function unitfile_plu-webserver

function unitfile_plu-webserver() {
    sudo tee ${SYSTEMD_DIR}/plu-webserver.service > /dev/null << EOT
[Unit]
Description=paclink-unix_webserver
After=network.service
After=ax25dev.service
After=aprs-server.target

[Service]
ExecStart=/bin/bash -c '/usr/bin/nodejs /home/$USER/bin/webapp/plu-server.js'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOT
}

# ===== function unitfile_update
# systemd unit file copy

function unitfile_update() {

    echo " == unit file update"

    for unit_file in `echo "${SERVICE_NAMES}"` ; do
        unitfile_${unit_file}
    done
    $SYSTEMCTL daemon-reload
}

# ===== function systemd unit file check
# systemd unit file exists check

function unitfile_check() {

    retcode=0
    for file in `echo "${SERVICE_NAMES}"` ; do
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
        echo "All tracker systemd service files found"
    else
        echo "Creating tracker systemd service files."
        unitfile_update
        retcode=1
    fi
    return $retcode
}


# ===== tracker_debugstatus

function tracker_debugstatus() {

    # Get call sign
    # grep -i "^mycall" "$TRACKER_CFG_FILE"
    callsign=$(grep -i "^mycall" "$TRACKER_CFG_FILE" | cut -f3 -d' ')
    #echo "Call sign: $callsign"
    if [ "$callsign" == "NOCALL" ] ; then
        echo "Tracker not configured, call sign: $callsign"
    else
        echo "Using call sign: $callsign"
    fi

    # Get gps type
    # grep -i "^type" "$TRACKER_CFG_FILE"
    #gpstype=$(grep -A8 "^\[gps\]"  "$TRACKER_CFG_FILE" | grep -i "^type =" | cut -f3 -d' ')
    # reference sed -n '/\[gps\]/,/\[/p' /etc/tracker/aprs_tracker.ini
    gpstype=$(sed -n '/\[gps\]/,/\[/p'  "$TRACKER_CFG_FILE" | grep -i "^type =" | cut -f3 -d' ')

    #echo "gps type: $gpstype"
    if [ "$gpstype" != "gpsd" ] ; then
        echo "gps type needs to be gpsd, currently: $gpstype"
        echo "comment all type lines in [gps] section"
        sudo sed -e '/\[gps\]/,/\[/s/^\(^type =.*\)/#\1/g'  "$TRACKER_CFG_FILE"
        echo "uncomment gpsd line"
        # reference: sed -i '/^#.* 2001 /s/^#//' file
        sudo sed -ie '/\[gps\]/,/\[/s/^#type = gpsd/type = gpsd/g' "$TRACKER_CFG_FILE"
    else
        echo "gps type: $gpstype OK"
    fi

    echo
    echo "   $(tput bold)$(tput setaf 2) == Tracker systemctl unit file check$(tput sgr0)"
    unitfile_check

    for service in `echo "${SERVICE_NAMES}"` ; do
        echo
        echo "   $(tput bold)$(tput setaf 2) == Status: $service $(tput sgr0)"
        systemctl is-enabled $service
        systemctl --no-pager status $service
    done

    echo
    echo "Found $(cat /tmp/aprs_tracker.log | wc -l) lines in tracker log"
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

# ===== tracker_status

function tracker_status() {
    if [ ! -z $DEBUG ] ; then
        tracker_debugstatus
        return
    fi
    for service in `echo ${SERVICE_NAMES}` ; do
        status_service $service
        echo "Status for $service: $IS_RUNNING and $IS_ENABLED"
    done
}

# ===== function tracker start
function tracker_start() {
        if [ "$FORCE_UPDATE" = "true" ] ; then
            echo "DEBUG: Updating systemd unitfiles"
            unitfile_update
        fi
        for service in `echo "${SERVICE_NAMES}"` ; do
            start_service $service
        done
}

# ===== function tracker_stop
function tracker_stop() {

    echo
    echo "DEBUG: tracker_stop"
    echo

    for service in `echo "${SERVICE_NAMES}"` ; do

        if $SYSTEMCTL is-active --quiet "$service" ; then
            stop_service $service
        fi
    done
}


# ==== function display arguments used by this script

usage () {
	(
	echo "Usage: $scriptname [-f][-d][-h][status][stop][start]"
        echo "                  No args will show status tracker daemons"
        echo "                  args with dashes must come before other arguments"
        echo "  start           start required tracker processes"
        echo "  stop            stop all tracker processes"
        echo "  status          display status of all tracker processes"
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
        for service in `echo "${SERVICE_NAMES}"` ; do
            diff ${SYSTEMD_DIR}/${service}.service systemd
        done
        exit 0
   ;;
    -h|--help|-?)
        usage
        exit 0
   ;;
    stop)
        echo "Kill all tracker processes"
        # temporary until everything is started with systemd
        tracker_stop
        exit 0
    ;;
    start)
        tracker_start
        exit 0
    ;;
    status)

        tracker_status
        echo "Finished tracker status"
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

unitfile_check
tracker_status
