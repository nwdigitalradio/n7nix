#!/bin/bash
# chk_ports.sh
# - verify the ax25 port names are consistent with applications
#
# Set this statement to DEBUG=1 for debug echos
DEBUG=
EDIT_FLAG=0

scriptname="`basename $0`"

AX25_CFGDIR="/usr/local/etc/ax25"
AXPORTS_FILE="$AX25_CFGDIR/axports"
AX25D_FILE="$AX25_CFGDIR/ax25d.conf"
RMSGW_CHAN_FILE="/etc/rmsgw/channels.xml"
PLU_CFG_FILE="/usr/local/etc/wl2k.conf"
APRX_CFG_FILE="/etc/aprx.conf"
TRACKER_CFG_FILE="/etc/tracker/aprs_tracker.ini"
XASTIR_CFG_FILE="$HOME/.xastir/config/xastir.cnf"

PRIMARY_DEVICE="udr0"
ALTERNATE_DEVICE="udr1"


# ===== function dbgecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_ax25up
function is_ax25up() {
    ax25device=$1
    ip a show $ax25device up > /dev/null  2>&1
}

# ===== function get_axport_device
# Pull device names from string
function get_axport_device() {
    dev_str="$1"
    device_axports=$(echo $dev_str | cut -d ' ' -f1)
    callsign_axports=$(echo $dev_str | cut -d ' ' -f2)

    dbgecho "DEBUG: get_axport: arg: $dev_str, $device_axports"

    # Test if device string is not null
    if [ ! -z "$device_axports" ] ; then
        udr_device="$device_axports"
        echo "axport: found device: $udr_device, with call sign $callsign_axports"
    else
        echo "axport: NO ax25 devices found"
    fi
}

# ===== function create_axports_file
function create_axports_file() {
    sudo tee "$AXPORTS_FILE" > /dev/null << EOT
# $AXPORTS_FILE
#
# The format of this file is:
# portname  callsign      speed   paclen  window   description
${PRIMARY_DEVICE}        $CALLSIGN-10       9600    255     2       Winlink port
${ALTERNATE_DEVICE}        $CALLSIGN-$SSID        9600    255     2       Direwolf port
EOT

}

# ===== function device_axports
# Pull device names from the /etc/ax25/axports file
function axports_edit_check () {
    # Is edit flag set?
    if [ "$EDIT_FLAG" -eq "1" ] ; then
        # Get callsign, callsign sid & ax25 port name
        SSID=$(echo $callsign_axports | cut -d'-' -f2)
        CALLSIGN=$(echo $callsign_axports | cut -d'-' -f1)
        # Delete all non alpha characters
        AX25PORT_BASE=$(echo $device_axports | tr -cd '[:alpha:]')
        dbgecho "axports_edit_check: device: $device_axports, callsign sid: $SSID"

        if [ "$device_axports" == "$ALTERNATE_DEVICE" ] && [ "$SSID" -eq "10" ] ; then
            echo "axports edit file: port: $device_axports, port base: $AX25PORT_BASE, call:$callsign_axports, call base: $CALLSIGN"
            SSID="1"
            create_axports_file
#            sudo sed -i -e "/^udr1/ s/1/0/" "$AXPORTS_FILE" > /dev/null
        elif [ "$device_axports" == "$PRIMARY_DEVICE" ] && [ "$SSID" -eq "1" ] ; then
            echo "axports edit file: port: $device_axports, port base: $AX25PORT_BASE, call:$callsign_axports, call base: $CALLSIGN"
            SSID="1"
            create_axports_file
#            sudo sed -i -e "/^udr0/ s/0/1/" "$AXPORTS_FILE" > /dev/null
        else
            dbgecho "axports file ok"
        fi
    fi
}


# ===== function device_axports
# Pull device names from the /etc/ax25/axports file
function device_axports () {

    # Collapse all spaces on lines that do not begin with a comment
    getline=$(grep -v '^#' $AXPORTS_FILE | tr -s '[[:space:]] ')
    linecnt=$(wc -l <<< $getline)
    if (( linecnt == 0 )) ; then
        echo "No axports found in $AXPORTS_FILE"
        return
    else
        echo "axports: found $linecnt lines:"
        dbgecho "$getline"
        dbgecho
    fi

    while IFS= read -r line ; do
        get_axport_device "$line"
    done <<< $getline
}

# ===== function set_ax25d_device
# change device name in file
function set_ax25d_device() {
    if [ "$udr_device" == "$ALTERNATE_DEVICE" ] && [ "$EDIT_FLAG" -eq "1" ] ; then
        echo "ax25d_chan: Edit file"
        sudo sed -i -e "/$ALTERNATE_DEVICE/ s/$ALTERNATE_DEVICE/$PRIMARY_DEVICE/" "$AX25D_FILE" > /dev/null
    fi
}

# ===== function get_ax25d_device
# Pull device names from string
function get_ax25d_device() {
    dev_str="$1"
    udr_device=
    device_ax25d=$(echo $dev_str | cut -d ' ' -f3 | tr -d "]")
    callsign_ax25d=$(echo $dev_str | cut -d ' ' -f1 | tr -d "[")

    word_cnt=$(wc -w <<< $dev_str)

    dbgecho "DEBUG: get_ax25d: arg: $dev_str, word cnt: $word_cnt, device: $device_ax25d, call: $callsign_ax25d"
    if [[ "$word_cnt" -eq 1 ]] ; then
        device_ax25d=
        callsign_ax25d=$(echo $callsign_ax25d | tr -d "]")

        echo "No device associated with this call: $callsign_ax25d"
        return
    fi

    # Test if device string is not null
    if [ ! -z "$device_axports" ] ; then
        udr_device="$device_ax25d"
        echo "ax25d: found device: $udr_device, with call sign $callsign_ax25d"
    else
        echo "ax25d: Found NO ax25 devices"
    fi
}

# ===== function ax25d_chan
# Pull device name from the /etc/ax25/ax25d.conf file
function ax25d_chan () {
    linecnt=$(grep -c "^\[" "$AX25D_FILE")
    dbgecho "ax25d_chan: line cnt: $linecnt"

    getline=$(grep '^\[' "$AX25D_FILE")
    dbgecho "ax25d_chan: getline: $getline"

    if (( linecnt == 0 )) ; then
        echo "ax25d: No ports found in $AXPORTS_FILE"
        return
    elif (( linecnt > 2 )) ; then
        echo "ax25d: custom config file, with $linecnt entries"
    else
        dbgecho "ax25d: found $linecnt lines: $getline"
    fi

    # Iterate through all ax25d.conf entries
    itercnt=$linecnt
    while [[ $itercnt -gt 0 ]] ; do
        dev_string=$(grep -m "$itercnt" "^\[" <<< $getline | tail -n 1 )
        dbgecho "maxcnt: $itercnt, dev_string: $dev_string"

        get_ax25d_device "$dev_string"

        ((itercnt--))
    done

if [ 1 = 0  ] ; then
    echo
    echo "== old code"

    if (( linecnt > 1 )) ; then
        # First entry
        dev_string=$(head -n 1 <<< $getline)
        get_ax25d_device "$dev_string"

        # Second entry
        dev_string=$(tail -n 1 <<< $getline)
        get_ax25d_device "$dev_string"
        set_ax25d_device

    else
        # Only one entry
        get_ax25d_device "$getline"
        set_ax25d_device
    fi
fi
}

# ===== function plu_chan
# Pull device name from the /usr/local/etc/wl2k.conf file
function plu_chan () {
    dev_string=$(grep  'ax25port=' "$PLU_CFG_FILE" | cut -d '=' -f2)
    call_string=$(grep 'mycall=' "$PLU_CFG_FILE" | cut -d '=' -f2)
    if [ -z "$dev_string" ] ; then
        echo "paclink-unix not configured"
    else
        echo "plu: ax25port: $dev_string, call sign: $call_string"
        if [ "$EDIT_FLAG" -eq "1" ] && [ "$PRIMARY_DEVICE" != "$dev_string" ] ; then
            echo "plu_chan: edit file change: $dev_string to $PRIMARY_DEVICE"
            sudo sed -i -e "/ax25port=/ s/ax25port=.*/ax25port=$PRIMARY_DEVICE/" "$PLU_CFG_FILE" > /dev/null
        fi
    fi
}

# ===== function rmsgw_chan
# Pull device name from the /etc/rmsgw/channels.xml file
function rmsgw_chan () {
    # Collapse all spaces on lines that do not begin with a comment
    getchan=$(grep -i "channel name=" $RMSGW_CHAN_FILE | tr -s '[[:space:]] ')
    getcall=$(grep -i "callsign" $RMSGW_CHAN_FILE | tr -s '[[:space:]] ')
    call_name=$(echo $getcall | cut -d'>' -f2 | cut -d '<' -f1)
    callbase=$(echo $call_name | cut -d'-' -f1)

    if [ "$callbase" == "N0CALL" ] ; then
        echo "RMS Gateway not configured."
    else

        dbgecho "rmsgw_chan: $getchan, call sign: $getcall, call base: $callbase"
        chan_name=$(echo $getchan | cut -d'=' -f2 | cut -d ' ' -f1)
        # Remove surrounding quotes
        chan_name=${chan_name%\"}
        chan_name=${chan_name#\"}
        if [ "$chan_name" == "$ALTERNATE_DEVICE" ] && [ "$EDIT_FLAG" -eq "1" ] ; then
            echo "rmsgw_chan: edit file change: $chan_name to $PRIMARY_DEVICE"
            sudo sed -i -e "/channel name/ s/channel name=\"$ALTERNATE_DEVICE\"/channel name=\"$PRIMARY_DEVICE\"/" "$RMSGW_CHAN_FILE" > /dev/null
        fi
        echo "RMS gateway: chan_name: $chan_name, call sign: $call_name"
    fi
}

# ===== function aprx_chan
# pull call sign & ssid from aprx.conf file
function aprx_chan() {
    grep -m 1 -i "callsign\|^mycall" $APRX_CFG_FILE
}

# ===== function tracker_chan
# pull call sign & ssid from aprs_tracker.ini file
function tracker_chan() {
    grep -m1 -i "mycall" $TRACKER_CFG_FILE
}


# ===== function xastir_chan
# pull call sign & ssid from xastir file
function xastir_chan() {
    grep -i "^station_callsign" "$XASTIR_CFG_FILE"
}

# ===== function network_ports
function network_ports() {
    device="$1"
    ifconfig $device > /dev/null 2>&1
    if [ "$?" != 0 ] ; then
        echo "Device $device not available"
    else
        is_ax25up "$device"
        if [ "$?" -eq 0 ] ; then
            devstatus="and up"
        else
            devstatus="but down"
        fi
        echo "Device $device OK, $devstatus"
    fi
}

# ===== function usage
function usage() {
   echo "Usage: $scriptname [-d][-e][-h]" >&2
   echo " Displays or edits: $(basename "$AXPORTS_FILE"), $(basename "$AX25D_FILE"), $(basename "$RMSGW_CHAN_FILE"), $(basename "$PLU_CFG_FILE"), $(basename "$APRX_CFG_FILE"), $(basename "$TRACKER_CFG_FILE"), $(basename "$XASTIR_CFG_FILE")"
   echo " No command line args, will display port names in above files."
   echo "   -d        set debug flag"
   echo "   -e        set edit files flag"
   echo "   -n 0 or 1 set winlink device number, only used with -e option."
   echo "   -p        print files with port names."
   echo "   -h        no arg, display this message"
   echo
}

# ===== main

while [[ $# -gt 0 ]] ; do

    key="$1"
    case $key in
        -d)
            echo "AX25 check_ports debug flag set"
            DEBUG=1
        ;;
        -e)
            echo "$(tput setaf 6) Checking files for edit $(tput setaf 7)"
            EDIT_FLAG=1
        ;;
        -n)
            PRIMARY_DEV_NUM=$2
            re='^[0-9]+$'
            if ! [[ $PRIMARY_DEV_NUM =~ $re ]] ; then
                echo "$PRIMARY_DEV_NUM not a number"
                echo
                usage
                exit 1
            fi
            if [ "$PRIMARY_DEV_NUM" -eq 0 ] ; then
                PRIMARY_DEVICE="udr0"
                ALTERNATE_DEVICE="udr1"
            elif [ "$PRIMARY_DEV_NUM" -eq 1 ] ; then
                PRIMARY_DEVICE="udr1"
                ALTERNATE_DEVICE="udr0"
            else
                echo
                echo "Device number must be either 0 or 1, found: $PRIMARY_DEV_NUM"
                usage
                exit 1
            fi
            echo "Set winlink device to $PRIMARY_DEVICE"

            shift # past argument
        ;;
        -p)
            echo "File: $AXPORTS_FILE"
            cat "$AXPORTS_FILE"
            echo
            echo "File: $AX25D_FILE"
            cat "$AX25D_FILE"
            echo
            echo "File: $RMSGW_CHAN_FILE"
            grep -i "channel name=" "$RMSGW_CHAN_FILE"
            echo
            echo "File: $PLU_CFG_FILE"
            grep  'ax25port=' "$PLU_CFG_FILE"
            echo
            echo "File: $APRX_CFG_FILE"
            grep -i "callsign\|^mycall" $APRX_CFG_FILE
            echo
            echo "File: $TRACKER_CFG_FILE"
            grep -i callsign $TRACKER_CFG_FILE
            echo
            echo "File: $XASTIR_CFG_FILE"
            grep -i "^station_callsign" "$XASTIR_CFG_FILE"
            exit
        ;;
        -h)
            usage
            exit 1
        ;;
        *)
            echo "Undefined argument: $key"
            usage
            exit 1
        ;;
    esac
    shift # past argument or value
done

if [ "$EDIT_FLAG" -eq "1" ] ; then
    echo "$(tput setaf 1)Only run this script after an initial config$(tput setaf 7)"
fi

# Verify ax25 network devices are up
echo "== AX.25 network ports check"
network_ports "ax0"
network_ports "ax1"

# Check packet ports for consistency

chkfile="$AXPORTS_FILE"
echo
echo "== file: $chkfile check"
if [ -e "$chkfile" ] ; then
    device_axports
else
    echo "File: $chkfile does not exist"
fi

chkfile="$AX25D_FILE"
echo
echo "== file: $chkfile check"
if [ -e "$chkfile" ] ; then
    ax25d_chan
else
    echo "File: $chkfile does not exist"
fi

chkfile="$RMSGW_CHAN_FILE"
echo
echo -n "== file: $(basename $chkfile) check "
if [ -e "$chkfile" ] ; then
    rmsgw_chan
else
    echo "File: $chkfile does not exist"
fi

chkfile="$PLU_CFG_FILE"
echo -n "== file: $(basename $chkfile) check "
if [ -e "$chkfile" ] ; then
    plu_chan
else
    echo "File: $chkfile does not exist"
fi

chkfile="$APRX_CFG_FILE"
echo -n "== file: $(basename $chkfile) check "
if [ -e "$chkfile" ] ; then
    aprx_chan
else
    echo "File: $chkfile does not exist"
fi

chkfile="$TRACKER_CFG_FILE"
echo -n "== file: $(basename $chkfile) check "
if [ -e "$chkfile" ] ; then
    tracker_chan
else
    echo "File: $chkfile does not exist"
fi

chkfile="$XASTIR_CFG_FILE"
echo -n "== file: $(basename $chkfile) check "
if [ -e "$chkfile" ] ; then
    xastir_chan
else
    echo "File: $chkfile does not exist"
fi

