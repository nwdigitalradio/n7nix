#!/bin/bash
#
# Mainly for use with DRAWS hat to toggle between having direwolf
# control both channels or just one for HF use on the other

# In this example when configured for split channels:
#  - HF programs use the left mDin6 connector (GPIO 12)
#  - packet programs will use the right connector (GPIO 23)

# Split channel is enabled by having a file (split_channel) in
# directory /etc/ax25

# Uncomment this statement for debug echos
DEBUG=1
scriptname="`basename $0`"

bsplitchannel=false
SPLIT_CHANNEL_FILE="/etc/ax25/split_channel"
DIREWOLF_CFGFILE="/etc/direwolf.conf"
AX25_CFGDIR="/usr/local/etc/ax25"
AX25PORT="udr"

# ===== function ax25_status

function ax25_status() {

    device="ax0"
    ip addr show dev $device > /dev/null 2>&1
    if [ "$?" -ne 0 ] ; then
        echo "AX.25 device: $device not configured"
    else
        ipaddr=$(ip addr show dev $device | grep "inet " | grep -Po '(\d+\.){3}\d+' | head -1)
        echo "AX.25 device: $device successfully configured with ip: $ipaddr"
    fi

    device="ax1"
    ip addr show dev $device > /dev/null 2>&1
    if [ "$?" -ne 0 ] ; then
        echo "AX.25 device: $device not configured"
    else
        ipaddr=$(ip addr show dev $device | grep "inet " | grep -Po '(\d+\.){3}\d+' | head -1)
        echo "AX.25 device: $device successfully configured with ip: $ipaddr"
    fi
}

# ===== function is_direwolf
# Determine if direwolf is running

function is_direwolf() {
    # ardop will NOT work if direwolf or any other sound card program is running
    pid=$(pidof direwolf)
    retcode="$?"
    return $retcode
}

# ===== function is_splitchan

function is_splitchan() {

   retcode=1

    # ==== verify split channel file
    if [ -e "$SPLIT_CHANNEL_FILE" ] ; then
        # split channel file exists, anything in it
        if [ -s "$SPLIT_CHANNEL_FILE" ] ; then
            chan_state=$(grep -i split_chan "$SPLIT_CHANNEL_FILE" | cut -f2 -d' ')
            if [ "$chan_state" == "left" ] || [ "$chan_state" == "right" ] ; then
                retcode=0
            else
                retcode=1
            fi
        else
            # split_channel_file exists but is empty
            retcode=0
        fi
    else
        # split channel file does NOT exist
        retcode=1
    fi
    return $retcode
}

# ===== function display_service_status
function display_service_status() {
    service="$1"
    if systemctl is-enabled --quiet "$service" ; then
        enabled_str="enabled"
    else
        enabled_str="NOT enabled"
    fi

    if systemctl is-active --quiet "$service" ; then
        active_str="running"
    else
        active_str="NOT running"
    fi
    echo "Service: $service is $enabled_str and $active_str"
}

# ===== split_debugstatus

function split_debugstatus() {

    if [ -e "$SPLIT_CHANNEL_FILE" ] ; then
        # Get 'left' or 'right' channel (get last word in ADEVICE string)
        chan_lr=$(grep "^ADEVICE " $DIREWOLF_CFGFILE | grep -oE '[^-]+$')
        echo " == Split channel is enabled, Direwolf controls 1 channel ($chan_lr)"
        bsplitchannel=true

        echo
        echo "pulseaudio daemon status"
        systemctl --no-pager status pulseaudio
    else
        echo " == Direwolf controls both channels, split-channels is off"
        bsplitchannel=false
    fi

    # Verify sound card device
    echo
    echo " == ALSA sound card device"
    aplay -l | grep udrc

    # Verify Pulse Audio devices
    echo
    echo " == Pulse Audio devices"
    pactl list sinks | grep -A3 "Sink #"

    # check direwolf config file
    echo
    echo " == Verify direwolf config"

    file="$DIREWOLF_CFGFILE"
    echo "First device config in $file"
    grep -m1 "^ADEVICE"   "$file"
    grep -m1 "^ACHANNELS" "$file"
    grep -m1 "^PTT "  "$file"

    echo "Second device config in $file"
    # -m NUM, stop reading file after NUM matching lines
    cnt=$(grep -c "^ADEVICE"   "$file")
    if (( cnt > 1 )) ; then
        echo "There are $cnt active ADEVICE config lines."
        grep -m2 "^ADEVICE"   "$file" | tail -n1
    fi
    cnt=$(grep -c "^ACHANNELS"   "$file")
    if (( cnt > 1 )) ; then
        echo "There are $cnt active ACHANNELS config lines."
        grep -m2 "^ACHANNELS"   "$file" | tail -n1
    fi
    cnt=$(grep -c "^PTT"   "$file")
    if (( cnt > 1 )) ; then
        echo "There are $cnt active PTT config lines."
        grep -m2 "^PTT"   "$file" | tail -n1
    fi

    echo
    echo " == check ax25d file"

    file="/etc/ax25/ax25d.conf"
    echo "First occurrence in $file"
    grep -m1 "^\[" "$file"
    echo "Second occurrnece in $file"
    grep "^\[" "$file" | tail -n1

    # check axports file
    echo
    echo " == check axports file"
    file="$AX25_CFGDIR/axports"
    numports=$(grep -c "^$AX25PORT" $AX25_CFGDIR/axports)
    echo "AX.25 $AX25PORT configured with $numports port(s)"

    # get the first port line after the last comment
    tail -n3 $file | grep -v "#"

    # check ax25 status
    echo
    echo " == ax25 status"
    ax25_status
}

# ===== split_status

function split_status() {

    # ==== verify split channel file
    bsplitchannel=false
    split_status="disabled"

    if [ -e "$SPLIT_CHANNEL_FILE" ] ; then
        echo -n "split channel file exists "
        if [ -s "$SPLIT_CHANNEL_FILE" ] ; then
            echo "and contains:"
            schan=$(cat $SPLIT_CHANNEL_FILE | cut -f2 -d' ')
            if [ "$schan" != "off" ] ; then
                bsplitchannel=true
                split_status="enabled"
            fi
        else
            echo "and is empty"
            bsplitchannel=true
            split_status="enabled"
        fi
        cat "$SPLIT_CHANNEL_FILE"
    else
        echo "split channel file does NOT exist"
    fi
    echo "split channel is $split_status"

    # ==== verify pulse audio service
    display_service_status "pulseaudio"

    # ==== verify direwolf config

    is_direwolf
    if [ "$?" -eq 0 ] ; then
        # Direwolf is running, check for split channels
        is_splitchan
        if [ "$?" -eq 0 ] ; then
            # Get 'left' or 'right' channel from direwolf config (last word in ADEVICE string)
            chan_lr=$(grep "^ADEVICE " $DIREWOLF_CFGFILE | grep -oE '[^-]+$')
            echo "Direwolf is running with pid: $pid, Split channel is enabled, Direwolf controls $chan_lr channel only"
        else
            echo "Direwolf is running with pid: $pid and controls both channels"
        fi
    else
        echo "Direwolf is NOT running"
    fi

    echo -n "Check: "
    grep "^ADEVICE" /etc/direwolf.conf

    echo -n "Check: "
    grep -q "^ARATE " $DIREWOLF_CFGFILE
    if [ $? -ne 0 ] ; then
        echo "ARATE parameter NOT set in $DIREWOLF_CFGFILE"
    else
        arateval=$(grep "^ARATE " /etc/direwolf.conf | cut -f2 -d' ')
        echo "ARATE parameter already set to $arateval in direwolf config file."
    fi

    num_chan=$(grep "^ACHANNELS " /etc/direwolf.conf | cut -f2 -d' ')
    echo "Number of direwolf channels: $num_chan"
}

# ===== function usage
# Display program help info

function usage () {
	(
	echo "Usage: $scriptname [-d][-h]"
        echo "    -d switch to turn on verbose debug display"
        echo "    -h display this message."
	echo " exiting ..."
	) 1>&2
	exit 1
}

# ===== main

echo
while [[ $# -gt 0 ]] ; do

    key="$1"
    case $key in
        -d)
            echo "Split Channel Debug Status"
            split_debugstatus
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

split_status
exit 0
