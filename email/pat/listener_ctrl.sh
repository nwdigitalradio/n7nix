#/bin/bash
#
# pat_listen.sh
#
# Enable listen for pat
# - shut off paclink-unix wl2kax25d

scriptname="`basename $0`"
DEBUG=

DAEMON_CFG_FILE="ax25d.conf"
# Temporary for debug
# cp /etc/ax25/$DAEMON_CFG_FILE .



#        sudo sed -e '/\[gps\]/,/\[/s/^\(^type =.*\)/#\1/g'  "$TRACKER_CFG_FILE"
#        echo "uncomment gpsd line"
        # reference: sed -i '/^#.* 2001 /s/^#//' file

# [KF7FIT VIA udr0]
# NOCALL   * * * * * *  L
# default  * * * * * *  - pi /usr/local/bin/wl2kax25d wl2kax25d -c %U -a %d

# sed -ie '/\[gps\]/,/\[/s/^#type = gpsd/type = gpsd/g' "$TRACKER_CFG_FILE"
# tac ax25d.conf | sed '/wl2kax25/I,+3 d' | tac

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function delete wl2kax25d sections

function del_plu_listener() {

    tmpfile=$(mktemp /tmp/ax25d_edit.XXXXXX)
    echo "temporary file name: $tmpfile"

    tac $DAEMON_CFG_FILE > $tmpfile
    echo
    # echo "After tac:"
    # cat $tmpfile

    sed -ie '/wl2kax25/I,+3 d' $tmpfile
    tac $tmpfile > $DAEMON_CFG_FILE
    rm $tmpfile
}

# ===== function add wl2kax25d sections

function add_plu_listener() {

callsign_cnt=$(grep -c -i "$CALLSIGN" $DAEMON_CFG_FILE)
echo "Entries in daemon file: $callsign_cnt before"

PRIMARY_DEVICE="udr0"
SECONDARY_DEVICE="udr1"

sed "0,/ rmsgw /a\
#\
[${CALLSIGN}-10 VIA ${PRIMARY_DEVICE}]\
NOCALL   * * * * * *  L\
default  * * * * * *  - $USER /usr/local/bin/wl2kax25d wl2kax25d -c %U -a %d\
" $DAEMON_CFG_FILE

callsign_cnt=$(grep -c -i "$CALLSIGN" $DAEMON_CFG_FILE)
echo "Entries in daemon file: $callsign_cnt after"

}

# ===== function add pat ax25 listen service
# Use a heredoc to build the pat_ax25_listen.service file

function unitfile_pat() {
sudo tee /etc/systemd/system/pat_listen.service > /dev/null << EOT
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
}

# ===== function plu_status

function plu_status() {
    echo
    echo " === paclink-unix status"

    callsign_cnt=$(grep -c -i "$CALLSIGN" $DAEMON_CFG_FILE)
    wl2kax25d_cnt=$(grep -c -i "wl2kax25" $DAEMON_CFG_FILE)

    echo "Daemon file: Total entries: $callsign_cnt, wl2kax25 entries: $wl2kax25d_cnt"

}

# ===== function pat_status

function pat_status() {
    echo
    echo " === PAT status"
    process="pat"
    echo "DEBUG: "
    ps aux | grep -i pat | grep -v "grep"
    echo "end DEBUG"

    pid_pat="$(pidof $process)"
    ret=$?
    # Display process: name, pid, arguments
    if [ "$ret" -eq 0 ] ; then
        args=$(ps aux | grep "$pid_pat " | grep -v "grep" | head -n 1 | tr -s '[[:space:]]' | sed -n "s/.*$process//p")
        echo "proc $process: $ret, pid: $pid_pat, args: $args"
    else
        echo "proc $process: $ret, NOT running"
    fi
}

# ==== function display arguments used by this script

usage () {
	(
	echo "Usage: $scriptname [-f][-d][-h][status][stop][start][restart]"
        echo "                single letter args must come before other arguments"
        echo "  -a|--add      Add wl2kax25 listener"
        echo "  -d|--del      Delete wl2kax25 listener"
        echo "  -D            Set DEBUG flag"
        echo "  -h            Display this message."
        echo
	) 1>&2
	exit 1
}


# ===== main

# Find callsign Greedy match
CALLSIGN=$(grep -o -P '(?<=^\[).*(?=\])' $DAEMON_CFG_FILE | head -n 1 | cut -f1 -d'-')
dbgecho "Using call sign: $CALLSIGN"


while [[ $# -gt 0 ]] ; do
APP_ARG="$1"

case $APP_ARG in
    -D|--debug)
        DEBUG=1
        echo "Debug mode on"
    ;;
    -l)
       Echo "Specify listener name plu or pat"
    ;;
    status)
        pat_status
        plu_status
        exit 0
    ;;
    -d|--del)
        echo "Delete wl2kax25d section for $CALLSIGN"
	del_plu_listener
	echo "Restart AX.25 stack"
#	ax25-restart
	exit 0
    ;;
    -a|--add)
        echo "Add wl2kax25d section for $CALLSIGN"
	add_plu_listener
	echo "Restart AX.25 stack"
#	ax25-restart
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

echo "Default: show status of any listeners"
echo
cat $DAEMON_CFG_FILE
