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

bsplitchannel=false
SPLIT_CHANNEL_FILE="/etc/ax25/split_channel"
DIREWOLF_CFGFILE="/etc/direwolf.conf"

# ===== function start_service

function start_service() {
    service="$1"
    systemctl is-enabled "$service" > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "ENABLING $service"
        systemctl enable "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem ENABLING $service"
        fi
    fi
    systemctl --no-pager start "$service"
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
        systemctl disable "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem DISABLING $service"
        fi
    else
        echo "Service: $service already disabled."
    fi
    systemctl stop "$service"
    if [ "$?" -ne 0 ] ; then
        echo "Problem STOPPING $service"
    fi
}

# ===== function config_both_channels
# Edit direwolf.conf to used both channels of a DRAWS HAT
function config_both_channels() {

    sed -i -e "0,/^ADEVICE .*/ s/^ADEVICE .*/ADEVICE plughw:CARD=udrc,DEV=0 plughw:CARD=udrc,DEV=0/"  $DIREWOLF_CFGFILE
    sed -i -e '/^ACHANNELS 1/ s/1/2/' $DIREWOLF_CFGFILE

    # Assume direwolf config was previously set up for 2 channels
    sed -i -e "0,/^PTT GPIO.*/ s/PTT GPIO.*/PTT GPIO 12/" $DIREWOLF_CFGFILE
}

# ===== function config_single_channel
# Edit direwolf.conf to use right mDin6 connector only
function config_single_channel() {
    sed -i -e "0,/^ADEVICE .*/ s/^ADEVICE .*/ADEVICE draws-capture-right draws-playback-right/"  $DIREWOLF_CFGFILE
    sed -i -e '/^ACHANNELS 2/ s/2/1/' $DIREWOLF_CFGFILE
    sed -i -e "0,/^PTT GPIO.*/ s/PTT GPIO.*/PTT GPIO 23/" $DIREWOLF_CFGFILE
}

# ===== main

if [ -e "$SPLIT_CHANNEL_FILE" ] ; then
    echo "Toggle to direwolf controls both channels"
    bsplitchannel=false
    sudo rm "$SPLIT_CHANNEL_FILE"
    echo "rm ret code: $?"
    if [ -e "$SPLIT_CHANNEL_FILE" ] ; then
        echo "Toggle failed, $SPLIT_CHANNEL_FILE still exists"
        exit 1
    fi
else
    echo "Toggle to split channels, Direwolf has 1 channel, HF has 1 channel"
    bsplitchannel=true
    sudo touch $SPLIT_CHANNEL_FILE
    echo "touch ret code: $?"
fi

if $bsplitchannel ; then
    # Setup split channel
    start_service pulseaudio
    config_both_channels

# ===== Edit ax25d.conf
# Change RMS Gateway & paclink-unix p2p to use correct udr port name
# For split channel needs to be udr0


# ===== Edit axports
# make sure axports port names match ax25d.conf port names
# Only define 1 port

else
    # Setup direwolf controls both ports
    stop_service pulseaudio
    config_single_channel


fi
