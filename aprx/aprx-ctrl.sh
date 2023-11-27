#!/bin/bash
#
# aprx-ctrl.sh
#
# stop and disable aprx for system services.d
#
# cat /var/log/aprx/aprx-rf.log | tr -s '[[:space:]]' | cut -d' ' -f5 | grep -i "n7nix\|k7bls"
# sed -n -e 's/^.*N7NIX-4 //p' /var/log/aprx/aprx-rf.log | grep -i "n7nix\|k7bls"
#
# 2023-11-26 20:45:39.214 N7NIX-4   R JUPITR>APN382,N7NIX-4*,VA7BLD-12*,WIDE3-1:!4741.70NB12258.05W# MT. JUPITER   K7IDX
#

scriptname="`basename $0`"
DEBUG=

# Number of lines of log file to display
loglines=5

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function aprx_status

function aprx_status() {

echo " ==== uptime: $(uptime)"
echo " ==== pid: $(pidof aprx)"

echo
echo "==== Memory status"
free -m
df -H | grep "\/dev\/root"

echo
echo " ==== systemd status"
systemctl --no-pager status aprx

echo
echo " ==== journal status"
journalctl --no-pager -u aprx

if [ ! -z "$DEBUG" ] ; then
    echo
    echo " ==== aprx-rf log ALL"
    tail -n $loglines /var/log/aprx/aprx-rf.log
fi

echo
echo " ==== aprx-rf log n7nix or k7bls"
sed -n -e 's/^.*N7NIX-4 //p' /var/log/aprx/aprx-rf.log | grep -i "n7nix\|k7bls" | tail -n $loglines

echo
echo " ==== aprx log"
tail -n $loglines /var/log/aprx/aprx.log

}

# ==== function display arguments used by this script

usage () {
	(
	echo "Usage: $scriptname [-d][-h][status][stop][start][restart]"
        echo "  start           start required processes"
        echo "  stop            stop all processes"
        echo "  status          display status of aprx"
        echo "  restart         stop aprx then restart"
        echo "  -f | --force    Update all aprx systemd unit files"
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
        aprx_stop
        exit 0
    ;;
    start)
        aprx_start
        exit 0
    ;;
    restart)
        aprx_stop
        sleep  1
        aprx_start
        exit 0
    ;;
    status)
        aprx_status
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

aprx_status
