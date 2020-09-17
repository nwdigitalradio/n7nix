#!/bin/bash
#
# Use with DRAWS hat to toggle between having direwolf control both
# channels or just one channel and an HF app use the other.

# In this example when configured for split channels:
#  - HF programs use the right mDin6 connector (GPIO 23)
#  - packet programs direwolf/ax.25 will use the left connector (GPIO 12)
#
# To make direwolf NOT control any channels toggle split channel off
# and run ax25-stop
#
# Split channel is enabled in /etc/ax25/port.conf in
# with a speed= entry for port1: speed=off

# Uncomment this statement for debug echos
#DEBUG=1

scriptname="`basename $0`"

bsplitchannel=false

PORT_CFG_FILE="/etc/ax25/port.conf"
DIREWOLF_CFGFILE="/etc/direwolf.conf"
AX25_CFGDIR="/usr/local/etc/ax25"

AX25PORT="udr"
SYSTEMCTL="systemctl"

# Set connector to be either left or right
# This selects which mini Din 6 connector DIREWOLF will use on the DRAWS card.
# Default: direwolf controls channel 0 for the left mini din connector.
# Note: if you choose "right", then direwolf channel 0 moves to the right connector

CONNECTOR="left"

# ===== function dbgecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }


# ===== function start_service
function start_service() {
    service="$1"
    systemctl is-enabled "$service" > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "ENABLING $service"
        $SYSTEMCTL enable "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem ENABLING $service"
        fi
    fi
    $SYSTEMCTL --no-pager start "$service"
    if [ "$?" -ne 0 ] ; then
        echo "Problem starting $service"
    fi
}

# ===== function stop_service
function stop_service() {
    service="$1"
    systemctl is-enabled "$service" > /dev/null 2>&1
    if [ $? -eq 0 ] ; then
        echo "DISABLING $service"
        $SYSTEMCTL disable "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem DISABLING $service"
        fi
    else
        echo "Service: $service already disabled."
    fi
    $SYSTEMCTL stop "$service"
    if [ "$?" -ne 0 ] ; then
        echo "Problem STOPPING $service"
    fi
}

# ===== function config_dw_2chan
# Edit direwolf.conf to use both channels (channel 0 & 1) of a DRAWS HAT
function config_dw_2chan() {

    sudo sed -i -e "0,/^ADEVICE .*/ s/^ADEVICE .*/ADEVICE plughw:CARD=udrc,DEV=0 plughw:CARD=udrc,DEV=0/"  $DIREWOLF_CFGFILE
    sudo sed -i -e '/^ACHANNELS 1/ s/1/2/' $DIREWOLF_CFGFILE

    # Assume direwolf config was previously set up for 2 channels
    sudo sed -i -e "0,/^PTT GPIO.*/ s/PTT GPIO.*/PTT GPIO 12/" $DIREWOLF_CFGFILE
}

# ===== function config_dw_1chan

# Configure direwolf to use only one mDin6 connector
# - defaults to using left mDin6 connector

function config_dw_1chan() {
    sudo sed -i -e "0,/^ADEVICE .*/ s/^ADEVICE .*/ADEVICE draws-capture-$CONNECTOR draws-playback-$CONNECTOR/"  $DIREWOLF_CFGFILE
    sudo sed -i -e '/^ACHANNELS 2/ s/2/1/' $DIREWOLF_CFGFILE
#    sed -i -e "0,/^PTT GPIO.*/ s/PTT GPIO.*/PTT GPIO 23/" $DIREWOLF_CFGFILE
}

# ===== function turn split channel off
function split_chan_off() {

    newspeed_port1=1200
##11    sudo tee "$SPLIT_CHANNEL_FILE" > /dev/null <<< "split_chan off"
    sudo sed -i -e "/\[port1\]/,/\[/ s/^speed=.*/speed=$newspeed_port1/" $PORT_CFG_FILE
    bsplitchannel=false
}

# ===== function turn split channel on
function split_chan_on() {

    # Current config is set for both channels used by direwolf
    echo "Toggle for split channels, Direwolf has left channel, HF has right channel"

    sudo sed -i -e "/\[port1\]/,/\[/ s/^speed=.*/speed=off/" $PORT_CFG_FILE

##11  sudo tee "$SPLIT_CHANNEL_FILE" > /dev/null <<< "split_chan left"

    bsplitchannel=true
}

# ===== function split_chan_toggle
function split_chan_toggle() {
    # Test if split channel indicator file exists
    if [ -e "$PORT_CFG_FILE" ] ; then
        portname=port1
        PORTSPEED=$(sed -n "/\[$portname\]/,/\[/p" $PORT_CFG_FILE | grep -i "^speed" | cut -f2 -d'=')
        if [ "$PORTSPEED" == "off" ] ; then
            # Current config is set for split channel
            echo "Toggle so direwolf controls both channels"
            dbgecho "split_chan_on 1"
            split_chan_on
        else
            dbgecho "split_chan_off 1"
            split_chan_off
        fi
    else
       dbgecho "split_chan_on 2"
       # Get here if cfg port file does not exist
       echo "No port config file: $PORT_CFG_FILE found, copying from repo."
       sudo cp $HOME/n7nix/ax25/port.conf $PORT_CFG_FILE
    fi
}
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

# ===== function is_pulseaudio
# Determine if pulse audio is running

function is_pulseaudio() {
    pid=$(pidof pulseaudio)
    retcode="$?"
    return $retcode
}

# ===== function is_splitchan

function is_splitchan() {

    retcode=1

    # ==== verify port config file
    if [ -e "$PORT_CFG_FILE" ] ; then
        portname=port1
        PORTSPEED=$(sed -n "/\[$portname\]/,/\[/p" $PORT_CFG_FILE | grep -i "^speed" | cut -f2 -d'=')

        case $PORTSPEED in
            1200 | 9600)
                dbgecho "parse baud_$PORTSPEED section for $portname"
            ;;
            off)
                echo "Using split channel, port: $portname is off"
                retcode=0
            ;;
            *)
                echo "Invalid speed parameter: $PORTSPEED, found in $PORT_CFG_FILE"
            ;;
        esac

    else
        # port config file does NOT exist
        echo "Port config file: $PORT_CFG_FILE NOT found."
        retcode=3
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

    is_splitchan
    splitchan_result=$?
    if [ "$splitchan_result" -eq "1" ] ; then
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

    is_pulseaudio
    if [ "$?" -ne 0 ] ; then
        echo " == Pulse Audio is NOT RUNNING."
    else
        pactl list sinks | grep -A3 "Sink #"
    fi

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

    if [ -e "$PORT_CFG_FILE" ] ; then
        echo -n "Port config file exists "
        portname=port1
        PORTSPEED=$(sed -n "/\[$portname\]/,/\[/p" $PORT_CFG_FILE | grep -i "^speed" | cut -f2 -d'=')
        if [ "$PORTSPEED" == "off" ] ; then
            # Current config is set for split channel
                bsplitchannel=true
                split_status="enabled"
        else
            # Current config is set for packet on both channels
                bsplitchannel=false
                split_status="DISabled"
       fi

       echo "split channel is $split_status"
    else
       # Get here if cfg port file does not exist
       echo "No port config file: $PORT_CFG_FILE found!!"
    fi

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

# ===== Display program help info
usage () {
	(
	echo "Usage: $scriptname [-c][-d][-h]"
        echo "                  No args will toggle split channel state."
#        echo "  -c right | left Specify either right or left connector for Direwolf."
        echo "  -c              Set split channels, left connector for Direwolf."
        echo "  -d              Set DEBUG flag"
        echo "  -s              Display split channel status"
        echo "  -h              Display this message."
        echo
	) 1>&2
	exit 1
}

# ===== main

# Check if running as root
if [[ $EUID != 0 ]] ; then
    dbgecho "set sudo"
    SYSTEMCTL="sudo systemctl"
else
    if [ -e "$PORT_CFG_FILE" ] ; then
        echo "Running as root"
    else
        echo "Running as root and no port config file found ... exiting"
        exit 1
    fi
fi

# Check for any command line arguments
# Command line args are passed with a dash & single letter
#  See usage function

while [[ $# -gt 0 ]] ; do

    key="$1"
    case $key in
        -d)
            DEBUG=1
        ;;
        -c)
            # Set split channel and which connector for Direwolf to use
        if [ 1 -eq 0 ] ; then
            CONNECTOR="$2"
            shift # past argument
            if [ "$CONNECTOR" != "right" ] && [ "$CONNECTOR" != "left" ] ; then
                echo "Connector argument must either be left or right, found '$CONNECTOR'"
                exit
            fi
         else
             # Set Direwolf connector to left
             CONNECTOR="left"
         fi
            echo "Set Direwolf connector to: $CONNECTOR"
            # Setup split channel
            start_service pulseaudio
            config_single_channel
            ax25-restart
            if [ ! -z "$DEBUG" ] ; then
                # ==== verify direwolf service
                display_service_status "direwolf"
            fi
            exit 0
        ;;
        -s)
            # display split channel status
            if [ ! -z "$DEBUG" ] ; then
                split_debugstatus
            else
                split_status
            fi
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

split_chan_toggle

dbgecho "bsplitchannel is $bsplitchannel"

if $bsplitchannel ; then
    # Setup split channel
    start_service pulseaudio
    config_dw_1chan
    split_chan_on

    # ===== Edit ax25d.conf
    # Change RMS Gateway & paclink-unix p2p to use correct udr port name
    # For split channel needs to be udr0

    # ===== Edit axports
    # make sure axports port names match ax25d.conf port names
    # Only define 1 port

else
    # Setup direwolf controls both ports
    service="pulseaudio"
    if systemctl is-active --quiet "$service" ; then
        stop_service $service
    else
        echo "Service: $service is already stopped"
    fi

    config_dw_2chan
    split_chan_off
fi

# restart direwolf
ax25-stop
ax25-start

# ==== verify direwolf service
display_service_status "direwolf"
