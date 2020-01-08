#!/bin/bash
#
# Use with DRAWS hat to toggle between having direwolf control both
# channels or just one channel and an HF app use on the other

# In this example when configured for split channels:
#  - HF programs use the right mDin6 connector (GPIO 23)
#  - packet programs direwolf/ax.25 will use the left connector (GPIO 12)
#
# To make direwolf NOT control any channels toggle split channel off
# and run ax25-stop
#
# Split channel is enabled by having a file (split_channel) in
# directory /etc/ax25 with a single entry of either:
# split_chan left or split_chan right

# Uncomment this statement for debug echos
#DEBUG=1

scriptname="`basename $0`"

bsplitchannel=false
SPLIT_CHANNEL_FILE="/etc/ax25/split_channel"
DIREWOLF_CFGFILE="/etc/direwolf.conf"
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

# ===== function config_both_channels
# Edit direwolf.conf to use both channels (channel 0 & 1) of a DRAWS HAT
function config_both_channels() {

    sudo sed -i -e "0,/^ADEVICE .*/ s/^ADEVICE .*/ADEVICE plughw:CARD=udrc,DEV=0 plughw:CARD=udrc,DEV=0/"  $DIREWOLF_CFGFILE
    sudo sed -i -e '/^ACHANNELS 1/ s/1/2/' $DIREWOLF_CFGFILE

    # Assume direwolf config was previously set up for 2 channels
    sudo sed -i -e "0,/^PTT GPIO.*/ s/PTT GPIO.*/PTT GPIO 12/" $DIREWOLF_CFGFILE
}

# ===== function config_single_channel
# Edit direwolf.conf to use right mDin6 connector only
function config_single_channel() {
    sudo sed -i -e "0,/^ADEVICE .*/ s/^ADEVICE .*/ADEVICE draws-capture-$CONNECTOR draws-playback-$CONNECTOR/"  $DIREWOLF_CFGFILE
    sudo sed -i -e '/^ACHANNELS 2/ s/2/1/' $DIREWOLF_CFGFILE
#    sed -i -e "0,/^PTT GPIO.*/ s/PTT GPIO.*/PTT GPIO 23/" $DIREWOLF_CFGFILE
}

# ===== function turn split channel off
function split_chan_off() {
    sudo tee "$SPLIT_CHANNEL_FILE" > /dev/null <<< "split_chan off"
    bsplitchannel=false
}

# ===== function turn split channel on
function split_chan_on() {
    # Current config is set for both channels used by direwolf
    echo "Toggle for split channels, Direwolf has left channel, HF has right channel"
    sudo tee "$SPLIT_CHANNEL_FILE" > /dev/null <<< "split_chan left"

    bsplitchannel=true
}

# ===== function split_chan_toggle

function split_chan_toggle() {
    # Test if split channel indicator file exists
    if [ -e "$SPLIT_CHANNEL_FILE" ] ; then
        # Current config is set for split channel
        echo "Toggle so direwolf controls both channels"
        # Check if there is any config in the file
        if [ -s "$SPLIT_CHANNEL_FILE" ] ; then
            chan_state=$(grep -i split_chan "$SPLIT_CHANNEL_FILE" | cut -f2 -d' ')
            retcode="$?"
            dbgecho "Retcode from grep splitchan: $retcode, state: $chan_state"
            if [ "$retcode" -eq 0 ] ; then
                if [ "$chan_state" == "left" ] || [ "$chan_state" == "right" ] ; then
                    dbgecho "split_chan_off 1"
                    split_chan_off
                else
                    dbgecho "split_chan_on 1"
                    split_chan_on
                fi
            fi
        else
            dbgecho "split_chan_off 2"
            split_chan_off
        fi


    else
       dbgecho "split_chan_on 2"
       # Get here if split channel file does not exist
       split_chan_on
    fi
}

# ===== Display program help info
#
usage () {
	(
	echo "Usage: $scriptname [-c][-d][-h]"
        echo "                  No args will toggle split channel state."
        echo "  -c right | left Specify either right or left connector for Direwolf."
        echo "  -d              Set DEBUG flag"
        echo "  -h              Display this message."
        echo
	) 1>&2
	exit 1
}

# ===== main

# Check if running as root
if [[ $EUID != 0 ]] ; then
   echo "set sudo"
   SYSTEMCTL="sudo systemctl"
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
            CONNECTOR="$2"
            shift # past argument
            if [ "$CONNECTOR" != "right" ] && [ "$CONNECTOR" != "left" ] ; then
                echo "Connectory argument must either be left or right, found '$CONNECTOR'"
                exit
            fi
            echo "Set connector to: $CONNECTOR"
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
    config_single_channel

    # ===== Edit ax25d.conf
    # Change RMS Gateway & paclink-unix p2p to use correct udr port name
    # For split channel needs to be udr0

    # ===== Edit axports
    # make sure axports port names match ax25d.conf port names
    # Only define 1 port

else
    # Setup direwolf controls both ports
    stop_service pulseaudio
    config_both_channels
    ax25-stop
    ax25-start
fi
