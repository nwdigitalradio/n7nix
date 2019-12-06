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


# ===== function dbgecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function usage
function usage() {
   echo "Usage: $scriptname [-d][-e][-h]" >&2
   echo " No command line args, will display port files information"
   echo "   -d        set debug flag"
   echo "   -e        set edit files flag"
   echo "   -p        print files with port names."
   echo "   -h        no arg, display this message"
   echo
}

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
#portname	callsign	speed	paclen	window	description
${AX25PORT_BASE}0        $CALLSIGN-10       9600    255     2       Winlink port
${AX25PORT_BASE}1        $CALLSIGN-$SSID        9600    255     2       Direwolf port
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

        if [ "$device_axports" == "udr1" ] && [ "$SSID" -eq "10" ] ; then
            echo "axports edit file: port: $device_axports, port base: $AX25PORT_BASE, call:$callsign_axports, call base: $CALLSIGN"
            SSID="1"
            create_axports_file
#            sudo sed -i -e "/^udr1/ s/1/0/" "$AXPORTS_FILE" > /dev/null
        elif [ "$device_axports" == "udr0" ] && [ "$SSID" -eq "1" ] ; then
            echo "axports edit file: port: $device_axports, port base: $AX25PORT_BASE, call:$callsign_axports, call base: $CALLSIGN"
            SSID="10"
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
#    getline=$(grep -v '^#' $AXPORTS_FILE )
    linecnt=$(grep -c "udr" <<< $getline)

    if (( linecnt == 0 )) ; then
        echo "No axports found in $AXPORTS_FILE"
        return
    else
        dbgecho "axports: found $linecnt lines: $getline"
    fi

    if (( linecnt > 1 )) ; then
        dev_string=$(head -n 1 <<< $getline)
        get_axport_device "$dev_string"
        axports_edit_check

        # File may have changed from axports_edit_check
        # Collapse all spaces on lines that do not begin with a comment
        getline=$(grep -v '^#' $AXPORTS_FILE | tr -s '[[:space:]] ')
        dev_string=$(tail -n 1 <<< $getline)
        get_axport_device "$dev_string"
        axports_edit_check
    else
        get_axport_device "$getline"
    fi
}

# ===== function set_ax25d_device
# change device name in file
function set_ax25d_device() {
    if [ "$EDIT_FLAG" -eq "1" ] ; then
        sudo sed -i -e "/^udr1/ s/1/0/" "$AXPORTS_FILE" > /dev/null
    fi
}

# ===== function get_ax25d_device
# Pull device names from string
function get_ax25d_device() {
    dev_str="$1"
    device_ax25d=$(echo $dev_str | cut -d ' ' -f3 | tr -d "]")
    callsign_ax25d=$(echo $dev_str | cut -d ' ' -f1 | tr -d "[")

    dbgecho "DEBUG: get_ax25d: arg: $dev_str, device: $device_ax25d, call: $callsign_ax25d"

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
        echo "ax25d: custom config file edit by hand."
        return
    else
        dbgecho "ax25d: found $linecnt lines: $getline"
    fi

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
        if [ "$dev_string" == "udr1" ] && [ "$EDIT_FLAG" -eq "1" ] ; then
            echo "plu_chan: edit file change: $dev_string to udr0"
            sudo sed -i -e "/ax25port=/ s/ax25port=.*/ax25port=udr0/" "$PLU_CFG_FILE" > /dev/null
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
        echo "RMS gateway: chan_name: $chan_name, call sign: $call_name"
    fi
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
    echo "File: $chk_file does not exist"
fi

chkfile="$AX25D_FILE"
echo
echo "== file: $chkfile check"
if [ -e "$chkfile" ] ; then
    ax25d_chan
else
    echo "File: $chk_file does not exist"
fi

chkfile="$RMSGW_CHAN_FILE"
echo
echo "== file: $chkfile check"
if [ -e "$chkfile" ] ; then
    rmsgw_chan
else
    echo "File: $chk_file does not exist"
fi

chkfile="$PLU_CFG_FILE"
echo
echo "== file: $chkfile check"
if [ -e "$chkfile" ] ; then
    plu_chan
else
    echo "File: $chk_file does not exist"
fi

