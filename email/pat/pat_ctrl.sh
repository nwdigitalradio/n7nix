#!/bin/bash
#

scriptname="`basename $0`"
PAT_CONFIG_FILE="${HOME}/.config/pat/config.json"

SYSTEMCTL="systemctl"

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

# ===== function start_pat_service

# Use a heredoc to build the pat_listen.service file
# then Start pat ax25 listen service


function start_pat_service() {

    callsign=$(grep -i "\"mycall\":" $PAT_CONFIG_FILE | cut -f2 -d':' | sed -e 's/^[[:space:]]*//' | cut -f2 -d'"')
    if [ -z "$callsign" ] ; then
        echo "${FUNCNAME[0]} No call sign found, must run $(tput setaf 6)pat_install.sh --config $(tput sgr0)before starting pat service"
	exit 1
    else
        echo "${FUNCNAME[0]} Found call sign: $callsign"
    fi

    # ==== pat_listen service
    service="pat_listen"
    pat_service_file="/etc/systemd/system/$service.service"

    if [ ! -e "$pat_service_file" ] ; then

    sudo tee $pat_service_file > /dev/null << EOT
[Unit]
Description=pat ax25 listener
After=network.target

[Service]
#User=pi
#type=forking
ExecStart=/usr/bin/pat --listen="ax25" "http"
WorkingDirectory=/home/pi/
StandardOutput=inherit
StandardError=inherit
Restart=no

[Install]
WantedBy=default.target
EOT
        $SYSTEMCTL daemon-reload
    else
        echo "PAT service file: $pat_service_file already exists."
    fi
    start_service $service

    # ==== pat service
    service="pat"
    pat_service_file="/etc/systemd/system/$service.service"

    if [ ! -e "$pat_service_file" ] ; then

    sudo tee $pat_service_file > /dev/null << EOT
[Unit]
Description=pat web app
After=network.target

[Service]
User=pi
Environment="HOME=/home/pi/"
ExecStart=/usr/bin/pat http
WorkingDirectory=/home/pi/
StandardOutput=inherit
StandardError=inherit
Restart=no

[Install]
WantedBy=default.target
EOT

        $SYSTEMCTL daemon-reload
    else
        echo "PAT service file: $pat_service_file already exists."
    fi
    start_service $service
}

# ===== function stop_pat_service
# Requires argument of "true" to kill pat process

function stop_pat_service() {

    kill_flag=$1
    if [ -z "$kill_flag" ] ; then
        echo "${FUNCNAME[0]} needs an argument"
	exit
    fi

    process="pat"

    pid_pat="$(pidof $process)"
    ret=$?
    # Display process: name, pid, arguments
    if [ "$ret" -eq 0 ] ; then
        args=$(ps aux | grep -i $pid_pat | grep -v "grep" | head -n 1 | tr -s '[[:space:]]' | sed -n "s/.*$process//p")
        echo "proc $process: $ret, pid: $pid_pat, args: $args"
    else
        echo "${FUNCNAME[0]} no process id found for $process"
    fi

    if $SYSTEMCTL is-active --quiet "$service" ; then
        stop_service $service
    else
        # kill process
        if [ "$ret" -eq 0 ] && [ "$kill_flag" = "true" ] ; then
            echo "$process running with pid: $pid_pat, killing"
            kill $pid_pat
        fi
    fi
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

# ===== function status_port

function status_port() {

    chk_port=$(sudo lsof -i -P -n | grep LISTEN | grep 8080)
    if [ $? -eq 0 ] ; then
        port_cmd=$(echo "$chk_port" | cut -f1 -d ' ')
        echo "Port 8080 is already in use by: $port_cmd"
    else
        echo "Port 8080 NOT in use"
    fi
}

# ==== function display arguments used by this script

usage () {
	(
	echo "Usage: $scriptname [-d][-h][status][stop][start]"
        echo "                  No args will show status"
        echo "  -d              Set DEBUG flag"
	echo
        echo "                  args with dashes must come before following arguments"
	echo
        echo "  start           start required PAT process"
        echo "  stop            stop all PAT process"
        echo "  status          display status of some processes"
        echo "  -h              Display this message."
        echo
	) 1>&2
	exit 1
}

# ===== main

# Check if running as root
if [[ $EUID != 0 ]] ; then
   SYSTEMCTL="sudo systemctl "
else
   SYSTEMCTL="systemctl"
fi

while [[ $# -gt 0 ]] ; do
APP_ARG="$1"

case $APP_ARG in
    -d|--debug)
        DEBUG=1
        echo "Debug mode on"
   ;;
    stop)
        echo "Kill PAT process"
        stop_pat_service
	exit 0
    ;;
    start)
        dbgecho "Finished starting PAT"
	start_pat_service
        exit 0
    ;;
    status)
        service="draws-manager"
        status_service $service
        echo " Status for systemd service: $service: $IS_RUNNING and $IS_ENABLED"

        service="pat"
        status_service $service
        echo " Status for systemd service: $service: $IS_RUNNING and $IS_ENABLED"

	# check for a PID of the PAT service
        pid_pat="$(pidof $service)"
        ret=$?
        # Display process: name, pid, arguments
        if [ "$ret" -eq 0 ] ; then
            args=$(ps aux | grep "$pid_pat " | grep -v "grep" | head -n 1 | tr -s '[[:space:]]' | sed -n "s/.*$service//p")
            echo "proc $service: $ret, pid: $pid_pat, args: $args"
        else
            echo "proc $service: $ret, NOT running"
        fi

	status_port
        exit 0
    ;;
    -h|--help|-?)
        usage
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

# Default to displaying status of draws_manager & PAT

service="draws-manager"
status_service $service
echo " Status for $service: $IS_RUNNING and $IS_ENABLED"
service="pat"
status_service $service
echo " Status for $service: $IS_RUNNING and $IS_ENABLED"

status_port

exit 0
