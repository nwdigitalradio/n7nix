#!/bin/bash
#
# Test Winlink connection to a single station or gateway
#
# Use like this:
#  psp-check.sh <some_callsign>
#
# Requires paclink-unix
# Logfile stored in $HOME/tmp/baudrate_test.log
# Useful for 9600 baud test to a station or gateway.

#DEBUG=

scriptname="`basename $0`"

LOCAL_BINDIR="/usr/local/bin"
TMPDIR="$HOME/tmp"
SPEED_LOGFILE="$TMPDIR/baudrate_test.log"
WL2KAX25="$LOCAL_BINDIR/wl2kax25"

# ===== function dbgecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== main

# Initialize counts
connect_count=0
connect_attempts=0

# Check command line argument
if [[ $# -ne 1 ]] ; then
    echo "  Must supply a call sign as argument"
    exit 1
fi

# First & only argument is call sign
callsign="$1"

# If logfile directory does not exist, create it.
if [ ! -d $TMP_DIR ] ; then
    mkdir -p $TMP_DIR
fi

# Log file will not exist until after first run
if [ -e "$SPEED_LOGFILE" ] ; then
    # Get current counts from log file
    connect_count=$(tail -n 1 $SPEED_LOGFILE | cut -f6 -d':' | cut -f1 -d',')
    connect_attempts=$(tail -n 1 $SPEED_LOGFILE | cut -f7 -d':' | cut -f1 -d',')

    # strip surronding white space
    connect_count=$(echo "${connect_count//[[:space:]]}")
    connect_attempts=$(echo "${connect_attempts//[[:space:]]}")
fi

    dbgecho "Using call sign: $callsign"
    dbgecho "Counts: connect: $connect_count, attempts: $connect_attempts"

start_sec=$SECONDS

$WL2KAX25 -c "$callsign"

retcode="$?"
duration=$((SECONDS-start_sec))

if [ "$retcode" -eq 0 ] ; then
    # Bump successful connect count
    connect_count=$((connect_count + 1))
    connect_status="OK"
    echo
    echo "Call to wl2kax25 connect OK"
else
    connect_status="fail"
    echo
    echo "Call to wl2kax25 timed out"
fi

# Bump total connect attempts
connect_attempts=$((connect_attempts + 1))

echo "$(date): $connect_status, time: $duration, connections: $connect_count, attempts: $connect_attempts" | tee -a $SPEED_LOGFILE
