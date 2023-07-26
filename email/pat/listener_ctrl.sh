#/bin/bash
#
# pat_listen.sh
#
# Enable listen for pat
# - shut off paclink-unix wl2kax25d

scriptname="`basename $0`"
DEBUG=

AX25_CONF_DIR="/etc/ax25"
AXPORTS_FILE="$AX25_CONF_DIR/axports"
DAEMON_CFG_FILE="$AX25_CONF_DIR/ax25d.conf"

PAT_CONF_FILE=$HOME/.config/pat/config.json

# ===== function get_axport_device
# Pull device names from string
function get_axport_device() {
    udr_device=
    dev_str="$1"
    device_axports=$(echo $dev_str | cut -d ' ' -f1)
    callsign_axports=$(echo $dev_str | cut -d ' ' -f2)

    dbgecho "DEBUG: get_axport: arg: $dev_str, $device_axports"

    # Test if device string is not null
    if [ ! -z "$device_axports" ] ; then
        udr_device="$device_axports"
        echo "axport: found device: $udr_device, with call sign $callsign_axports"
    else
        echo "axport: NO ax25 devices found in string: $dev_str"
    fi
}

function config_verify() {
    # Determine if PAT has been configured
    pat_callsign=$(grep -i "\"mycall\":" $PAT_CONF_FILE | cut -f2 -d':' | sed -e 's/^[[:space:]]*//' | cut -f2 -d'"')
    if [ -z "$pat_callsign" ] ; then
        echo "${FUNCNAME[0]} No call sign found in PAT config file, must run $(tput setaf 6)pat_install.sh --config $(tput sgr0)before starting pat service"
        exit 1
    else
        dbgecho "${FUNCNAME[0]} Found PAT call sign: $pat_callsign"
    fi
}

function test_only() {

    echo "List axport device names"
    # Debug only
    # grep -v '^#' $AXPORTS_FILE | tr -s '[[:space:]] '

    # Collapse all spaces on lines that do not begin with a comment
    getline=$(grep -v '^#' $AXPORTS_FILE | tr -s '[[:space:]] ')
    linecnt=$(wc -l <<< $getline)
    if (( linecnt == 0 )) ; then
        echo "No axports found in $AXPORTS_FILE"
        return
    else
        dbgecho "axports: found $linecnt lines:"
        dbgecho "$getline"
        dbgecho
    fi

    portcnt=0
    declare -A portname

    while IFS= read -r line ; do
        get_axport_device "$line"
	index=$((portcnt))
	dbgecho "index: $index, portcnt: $portcnt, udr: $udr_device"
	portname[ax$index]=$udr_device
	((portcnt++))
    done <<< $getline

    for key in "${!portname[@]}"; do
        echo -n "$key -> ${portname[$key]}, "
    done
    echo

    # Flag for indicating whether the AX.25 port in the PAT config file
    # is also in the AX.25 config files (ie. /etc/ax25/axports)
    b_portmatch="false"

    if [ -e $PAT_CONF_FILE ] ; then
        echo "Display listen ax.25 device"
	PAT_CFG="$PAT_CONF_FILE"
        # iterate through the JSON parsed file
	ax25_value=$(jq '.ax25["port"]' $PAT_CFG)
	#Remove surronding quotes
        ax25_value="${ax25_value%\"}"
        ax25_port="${ax25_value#\"}"
        echo "AX.25 port: $ax25_port"

        for key in "${!portname[@]}"; do
	    if [ ${portname[$key]} == $ax25_port ] ; then
	        # Found a match between PAT configured AX.25 port and a
	        # configured AX.25 port
                echo "Port match key: $key -> value: ${portname[$key]}, "
	        b_portmatch="true"
	    fi
        done

    else
        echo "PAT config file: $PAT_CONF_FILE does not exist"
    fi
    if [ "$b_portmatch" == "false" ] ; then
        echo "$(tput setaf 1)ERROR in PAT config file, PAT AX.25 port: $ax25_port does not match any configured AX.25 port$(tput sgr0)"
	echo "Will edit from script."
	# Variable to write to file
	# Assume want to use first AX.25 port name ax0
	ax25_port="${portname[ax0]}"
        # Write 1config variables to PAT config file
        jq --arg axport "${ax25_port}" '.ax25["port"] = $axport' $PAT_CONF_FILE  > temp.$$.json
        dbgecho "jq ret code: $?"
        echo "Updating PAT config file: $PAT_CONF_FILE"
	# Debug ONLY, look at .ax25["port"] value
        head -n 20 temp.$$.json
        #mv temp.$$.json $PAT_CONF_FILE
    fi
}

# Temporary for debug
# cp /etc/ax25/$DAEMON_CFG_FILE .



#        sudo sed -e '/\[gps\]/,/\[/s/^\(^type =.*\)/#\1/g'  "$TRACKER_CFG_FILE"
#        echo "uncomment gpsd line"
        # reference: sed -i '/^#.* 2001 /s/^#//' file

# [KF7FIT VIA udr0]
# NOCALL   * * * * * *  L
# default  * * * * * *  - $USER /usr/local/bin/wl2kax25d wl2kax25d -c %U -a %d

# sed -ie '/\[gps\]/,/\[/s/^#type = gpsd/type = gpsd/g' "$TRACKER_CFG_FILE"
# tac ax25d.conf | sed '/wl2kax25/I,+3 d' | tac

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function delete wl2kax25d sections

function del_plu_listener() {

    # Check for number of rmsgw entries
    rmsgw_cnt=$(grep -c -i "rmsgw rmsgw" $DAEMON_CFG_FILE)
    if ((rmsgw_cnt > 2 )) ; then
    echo
    echo "rmsgw Entries in daemon file: $rmsgw_cnt"
	echo "$(tput setaf 1) == Too many RMSGW entries, FIX THIS ==$(tput sgr0)"
        sudo sed -ie "$(( $(wc -l < $DAEMON_CFG_FILE)-3+1 )),$ d" $DAEMON_CFG_FILE
    fi

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
    sudo sed -ie '/wl2kax25/I,+3 d' $tmpfile
    tac $tmpfile | sudo tee $DAEMON_CFG_FILE > /dev/null
    rm $tmpfile

    # Delete second listener
    # /I case insensitive
    endlineno=$(grep -n "wl2kax25d" /etc/ax25/ax25d.conf | tail -n 1 | cut -f 1 -d ':')
    startlineno=(endlineno -3)

    dbgecho "Delete second occurrence"
    sudo sed -ie "/wl2kax25/I $startlineno,$endlineno d" $DAEMON_CFG_FILE

    callsign_cnt=$(grep -c -i "$CALLSIGN" $DAEMON_CFG_FILE)

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
WorkingDirectory=/home/$USER/
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

    rmsgw_cnt=$(grep -c -i "rmsgw rmsgw" $DAEMON_CFG_FILE)

    echo
    echo "rmsgw Entries in daemon file: $rmsgw_cnt"
    rmsgw_cnt=$(grep -c -i "$CALLSIGN" $DAEMON_CFG_FILE)
    if ((rmsgw_cnt > 2 )) ; then
	echo "$(tput setaf 1) == Too many RMSGW entries, FIX THIS ==$(tput sgr0)"
    fi


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
    # Display ax25 listen port
}

# ==== function display arguments used by this script

usage () {
	(
	echo "Usage: $scriptname [-f][-d][-h][status][stop][start][restart]"
        echo "                single letter args must come before other arguments"
        echo "  -A|--add      Add wl2kax25 listener"
        echo "  -D|--del      Delete wl2kax25 listener"
        echo "  -d            Set DEBUG flag"
        echo "  -h            Display this message."
	echo "  status        Display PAT & paclink-unix status"
        echo
	) 1>&2
	exit 1
}


# ===== main

if [[ $EUID == 0 ]] ; then
    echo "Do not run as root."
    exit 0
fi

config_verify

# Find ax25d callsign Greedy match
CALLSIGN=$(grep -o -P '(?<=^\[).*(?=\])' $DAEMON_CFG_FILE | head -n 1 | cut -f1 -d'-')
dbgecho "Using AX.25 daemon call sign: $CALLSIGN"


while [[ $# -gt 0 ]] ; do
APP_ARG="$1"

case $APP_ARG in
    -d|--debug)
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
    -D|--del)
        echo "Delete wl2kax25d section for $CALLSIGN"
	del_plu_listener
	if [ ! -z $DEBUG ] ; then
	    echo
            cat $DAEMON_CFG_FILE
	    echo
	fi

	# Is this required??
#	echo
#	echo "Restart AX.25 stack"
#	ax25-restart
	exit 0
    ;;
    -A|--add)
        echo "Add wl2kax25d section for $CALLSIGN"
	add_plu_listener
	if [ ! -z $DEBUG ] ; then
	    echo
            cat $DAEMON_CFG_FILE
	    echo
	fi

	echo
	echo "Restart AX.25 stack"
	ax25-restart
	exit 0
    ;;
    -t|--test)
        test_only
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
