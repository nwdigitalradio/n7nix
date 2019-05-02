#!/bin/bash
#
# Script to run C program gp_testport
# If program not found then it will build it

PROGRAM_VERSION="1.1"
scriptname="`basename $0`"
progname="gp_testport"
bverbose=false

# trap ctrl-c and call function ctrl_c()
trap ctrl_c INT

# ===== function stop_service

function stop_service() {
    service="$1"

    sudo systemctl stop "$service"
    if [ "$?" -ne 0 ] ; then
        echo "Problem stopping $service"
    fi
}

# ===== function service_start

function start_service() {
    service=$1
    if systemctl is-enabled --quiet "$service" ; then
        echo "Service $service already enabled"
    else
        echo "ENABLING $service"
        sudo systemctl enable "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem ENABLING $service"
        fi
    fi

    if systemctl is-active --quiet $service ; then
        echo "$service is already running."
    else
        sudo systemctl start --no-pager $service.service
    fi
}

# ===== function ctrl_c trap handler

function ctrl_c() {
        echo
        echo "Exiting script from trapped CTRL-C on $(date)"
        echo
        ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
        echo "$ELAPSED"
        echo "Cleaning up & starting gpsd"
        make clean > /dev/null 2>&1
        start_service "gpsd"
	exit
}

# ===== main

if [[ $# -gt 0 ]] ; then
    bverbose=true
fi

gpsd -V
stop_service "gpsd"

# Check for C source file to test gps port
if [ -e ${progname}.c ] ; then
    echo "Source file found, building"
    make $progname
else
    echo "Source file: ${progname}.c not found"
fi

if ! type -P ./$progname >/dev/null 2>&1 ; then
    echo "No binary file found ... exiting"
    exit 1
fi
echo "$scriptname: version: $PROGRAM_VERSION, $(./$progname -V)"


# Reset bash time counter
SECONDS=0

if $bverbose ; then
    echo "Running in verbose mode"
    ./$progname -v
else
    echo "Running in sat count mode"
    ./$progname
fi
retcode="$?"

if [ "$retcode" == 0 ] ; then
    echo "Success"
else
    echo "$progname Error: $retcode"
fi

echo
echo "Exiting script from C program failure at: $(date)"
ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo "$ELAPSED"
