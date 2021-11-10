#!/bin/bash
#

scriptname="`basename $0`"

SYSTEMCTL="systemctl"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function stop_service

function stop_service() {

    kill_flag=$1

    service="pat"
    process="pat"

    pid_pat="$(pidof $process)"
    ret=$?
    # Display process: name, pid, arguments
    if [ "$ret" -eq 0 ] ; then
        args=$(ps aux | grep -i $pid_pat | grep -v "grep" | head -n 1 | tr -s '[[:space:]]' | sed -n "s/.*$process//p")
        echo "proc $process: $ret, pid: $pid_pat, args: $args"
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
        stop_service true
	exit 0
    ;;
    start)
        dbgecho "Finished starting PAT"
        exit 0
    ;;
    status)
        service="draws-manager"
        status_service $service
        echo " Status for $service: $IS_RUNNING and $IS_ENABLED"
        service="pat"
        status_service $service
        echo " Status for $service: $IS_RUNNING and $IS_ENABLED"
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


service="draws-manager"
status_service $service
echo " Status for $service: $IS_RUNNING and $IS_ENABLED"
service="pat"
status_service $service
echo " Status for $service: $IS_RUNNING and $IS_ENABLED"

status_port

exit 0
