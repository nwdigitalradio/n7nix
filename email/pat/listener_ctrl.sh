#/bin/bash
#
# pat_listen.sh
#
# Enable listen for pat
# - shut off paclink-unix wl2kax25d

scriptname="`basename $0`"
DEBUG=

AX25_CONF_DIR="/etc/ax25"
DAEMON_CFG_FILE="$AX25_CONF_DIR/ax25d.conf"

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

   grep -iq "wl2kax25d" $DAEMON_CFG_FILE
   if [ "$?" = 1 ] ; then
       echo
       echo "No paclink-unix listeners are configured."
       return
   fi

    callsign_cnt=$(grep -c -i "$CALLSIGN" $DAEMON_CFG_FILE)
    echo
    echo "Entries in daemon file: $callsign_cnt before"

   # Delete first listener
    tmpfile=$(mktemp /tmp/ax25d_edit.XXXXXX)
    # echo "temporary file name: $tmpfile"

    tac $DAEMON_CFG_FILE > $tmpfile
    # echo
    # echo "After tac:"
    # cat $tmpfile

    dbgecho "Delete first occurrence"
    sed -ie '/wl2kax25/I,+3 d' $tmpfile
    tac $tmpfile | sudo tee $DAEMON_CFG_FILE > /dev/null
    rm $tmpfile

    # Delete second listener
    # /I case insensitive
    endlineno=$(grep -n "wl2kax25d" /etc/ax25/ax25d.conf | tail -n 1 | cut -f 1 -d ':')
    startlineno=(endlineno -3)

    dbgecho "Delete second occurrence"
    sudo sed -ie "/wl2kax25/I $startlineno,$endlineno d" $DAEMON_CFG_FILE

    callsign_cnt=$(grep -c -i "$CALLSIGN" $DAEMON_CFG_FILE)

    echo "Entries in daemon file: $callsign_cnt after"
}

# ===== function add wl2kax25d sections

function add_plu_listener() {

    callsign_cnt=$(grep -c -i "$CALLSIGN" $DAEMON_CFG_FILE)
    echo
    echo "Entries in daemon file: $callsign_cnt before"

   listener_cnt=$(grep -ic "wl2kax25d" $DAEMON_CFG_FILE)
   if [ $listener_cnt -ne 0 ] ; then

       echo
       echo " Some paclink-unix listener(s) already configured."
       echo " NO additional listeners added."
       return
   fi


    PRIMARY_DEVICE="udr0"
    SECONDARY_DEVICE="udr1"

    # sudo sed -i -e "0,/ rmsgw /a\

# Replacement section
if [ 1 -eq 0 ] ; then

    sudo sed  "0,/ rmsgw /a\
    #\
    [${CALLSIGN}-10 VIA ${PRIMARY_DEVICE}]\
    NOCALL   * * * * * *  L\
    default  * * * * * *  - $USER /usr/local/bin/wl2kax25d wl2kax25d -c %U -a %d\
    " $DAEMON_CFG_FILE

else

#\[${CALLSIGN} VIA ${PRIMARY_DEVICE}\]\n\
#NOCALL   * * * * * *  L\n\
#default  * * * * * *  - $USER /usr/local/bin/wl2kax25d wl2kax25d -c %U -a %d\n\
    if [ ! -z $DEBUG ] ; then
        lineno=$(grep -n "^default" /etc/ax25/ax25d.conf | head -n 1 | cut -f 1 -d ':')
        echo "Add first occurrence after line: $lineno"
    fi
# add after first occurrence of paclink-unix listener
    sudo sed -i "0,/^default/!b;//a \
# paclink-unix listener\n\
\[${CALLSIGN} VIA ${PRIMARY_DEVICE}\]\n\
NOCALL   * * * * * *  L\n\
default  * * * * * *  - $USER /usr/local/bin/wl2kax25d wl2kax25d -c %U -a %d\
" $DAEMON_CFG_FILE

    if [ ! -z $DEBUG ] ; then
        lineno=$(grep -n "^default" /etc/ax25/ax25d.conf | tail -n 1 | cut -f 1 -d ':')
        echo "Add second occurrence after line: $lineno"
    fi

# Add second occurrence of paclink-unix listener
# Add after last occurrence based on line number
lineno=$(grep -n "^default" /etc/ax25/ax25d.conf | tail -n 1 | cut -f 1 -d ':')

    sudo sed  -i "$lineno a \
# paclink-unix listener\n\
\[${CALLSIGN} VIA ${SECONDARY_DEVICE}\]\n\
NOCALL   * * * * * *  L\n\
default  * * * * * *  - $USER /usr/local/bin/wl2kax25d wl2kax25d -c %U -a %d\
" $DAEMON_CFG_FILE

fi  # end replacement section

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
	echo "  status        Display PAT & paclink-unix status"
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
        # Display all lines without a comment character
        grep ^[^#] $DAEMON_CFG_FILE
        exit 0
    ;;
    -d|--del)
        echo "Delete wl2kax25d section for $CALLSIGN"
	del_plu_listener
	if [ ! -z $DEBUG ] ; then
	    echo
            cat $DAEMON_CFG_FILE
	    echo
	fi

	echo
	echo "Restart AX.25 stack"
#	ax25-restart
	exit 0
    ;;
    -a|--add)
        echo "Add wl2kax25d section for $CALLSIGN"
	add_plu_listener
	if [ ! -z $DEBUG ] ; then
	    echo
            cat $DAEMON_CFG_FILE
	    echo
	fi

	echo
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
