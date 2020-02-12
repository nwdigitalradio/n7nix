#!/bin/bash
#
# Refresh the source code from the repository
#
DEBUG=

scriptname="`basename $0`"
user=$(whoami)

SRC_DIR="$HOME/dev"
TRACKER_SRC_DIR="$SRC_DIR/nixtracker"
LOCAL_BIN_DIR="$HOME/bin"
GLOBAL_BIN_DIR="/usr/local/bin"

TRACKER_CFG_DIR="/etc/tracker"
TRACKER_CFG_FILE="$TRACKER_CFG_DIR/aprs_tracker.ini"

# ===== function check_repo
function check_repo() {

#    commit_cnt=$(git rev-list HEAD...origin/master --count)
    git_out=$(git pull)
    grep -iq "Already up to date" <<< "$git_out"
    if [ "$?" -eq 0 ] ; then
        echo "Local repo is up-to-date"
    else
        echo "Local repo was refreshed."
    fi
}

# ===== function update_webfiles
# Only copies files that are changed.

function update_webfiles() {
   rsync -av $TRACKER_SRC_DIR/webapp $LOCAL_BIN_DIR
   rsync -av $TRACKER_SRC_DIR/images $LOCAL_BIN_DIR/webapp
}

# ===== function tracker-status
function tracker_status() {
    progname="aprs"
    type -P $prog_name &>/dev/null
    if [ $? -ne 0 ] ; then
        echo "$scriptname: $progname not installed properly"
    else
        echo "$scriptname: $progname is installed"
    fi

    sudo screen -ls

    process_name="aprs"
    pid=$(pidof $process_name)
    if [ $? -eq 0 ] ; then
       echo "$process_name is running, with a pid of $pid"
    else
       echo "$process_name is NOT running"
    fi

    process_name="plu-server"
    pid=$(pidof $process_name)
    if [ $? -eq 0 ] ; then
       echo "$process_name is running, with a pid of $pid"
    else
       echo "$process_name is NOT running"
    fi

    process_name="tracker-server"
    pid=$(pidof $process_name)
    if [ $? -eq 0 ] ; then
        echo "$process_name is running, with a pid of $pid"
    else
        echo "$process_name is NOT running"
    fi
}

# ===== function usage
# Display program help info

function usage () {
	(
	echo "Usage: $scriptname [-d][-s]"
        echo "    -d switch to turn on verbose debug display"
        echo "    -s Display status of install only."
        echo "    -h display this message."
	echo " exiting ..."
	) 1>&2
	exit 1
}

# ===== main

while [[ $# -gt 0 ]] ; do

    key="$1"
    case $key in
        -d)
            echo "Set debug flag"
            DEBUG=1
        ;;
        -s)
            echo
            echo "Status of Install"
            echo
            tracker_status
            exit 0
        ;;
        -h)
            usage
            exit 0
        ;;
        *)
            echo "Undefined argument: $key"
            usage
            exit 1
        ;;
    esac
    shift # past argument or value
done

# Check that gps serial port is not being configured.
#  ie. comment it out and use gpsd
#port = /dev/ttyUSB0

portline=$(sed -n '/\[gps\]/,/\[/p' $TRACKER_CFG_FILE | grep -i "^port =")
if [ "$?" -ne 1 ] ; then
    echo "Editing port = in gps section"
    sudo sed -ie '/\[gps\]/,/\[/s/^\(^port =.*\)/#\1/g'  "$TRACKER_CFG_FILE"
else
    echo "tracker config file OK."
fi

# Verify that a valid tracker was previously installed
local_dir="$LOCAL_BIN_DIR/webapp/jQuery"
if [ ! -d  $local_dir ] ; then
    echo "No jQuery directory ($local_dir), found, bad install."
    exit 1
fi

# Refresh any source files, rebuild & install.

cd
cd dev/nixtracker
echo " == Check if source files are up-to-date"
check_repo

echo " == Copy installed webapp files"

update_webfiles

echo " == Build nixtracker"
make

echo " == Install nixtracker binary"
cp aprs $LOCAL_BIN_DIR
# Change directory to local bin dir
cd
cd bin

# Must stop the tracker before updating
sudo ./tracker-down
sudo cp $HOME/dev/nixtracker/aprs $GLOBAL_BIN_DIR
sudo ./tracker-up

echo " == test if nixtracker is running"
tracker_status
