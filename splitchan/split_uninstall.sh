#!/bin/bash
#
# Script to UNinstall split-channel functionality
#
# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"

PORT_CFG_FILE="/etc/ax25/port.conf"
DIREWOLF_CFGFILE="/etc/direwolf.conf"

USER=
SYSTEMCTL="systemctl"

# ===== function dbgecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

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

function uncomment_second_chan() {
    # Set up the second channel
    # CHANGE: THIS NEEDS SOME WORK
    dbgecho "uncomment CHANNEL 1"
    # Uncomment CHANNEL 1 line
    sed -i -e "/^#CHANNEL 1/,/^$/s/^#CHANNEL 1/CHANNEL 1/" $DIREWOLF_CFGFILE

    # dbgecho "uncomment PTT GPIO"
    sed -i -e "/^CHANNEL 1/,/^$/s/^#\(PTT GPIO.*\)/\1/" $DIREWOLF_CFGFILE

    # dbgecho "uncomment MODEM"
    sed -i -e "/^CHANNEL 1/,/^$/s/^#\(MODEM.*\)/\1/" $DIREWOLF_CFGFILE

    # dbgecho "uncomment MYCALL"
    sed -i -e "/^CHANNEL 1/,/^$/s/^#\(MYCALL.*\)/\1/" $DIREWOLF_CFGFILE
}

# ===== function config_dw_2chan
# Modify direwolf configuration file

function config_dw_2chan() {

    echo "Edit direwolf config file"

    #  - both CHANNELS are used for packet
    # Change ACHANNELS from 1 to 2
    dbgecho "ACHANNELS set to 2"
    sudo sed -i -e '/^ACHANNELS 1/ s/1/2/' $DIREWOLF_CFGFILE

    # Leave ARATE 48000 unchanged
    dbgecho "Check for ARATE parameter"
    grep "^ARATE 48000" $DIREWOLF_CFGFILE
    if [ $? -ne 0 ] ; then
        echo "ARATE parameter NOT found."
    else
        echo "ARATE parameter already set in direwolf config file."
    fi

    # Change ADEVICE:
    #  to: ADEVICE plughw:CARD=udrc,DEV=0 plughw:CARD=udrc,DEV=0
    dbgecho "ADEVICE"

    sudo sed -i -e "0,/^ADEVICE .*/ s/^ADEVICE .*/ADEVICE plughw:CARD=udrc,DEV=0 plughw:CARD=udrc,DEV=0/"  $DIREWOLF_CFGFILE

    echo "Verify ADEVICE parameter"
    grep -i "^ADEVICE" $DIREWOLF_CFGFILE

    # Set up the second channel
    # CHANGE: THIS NEEDS SOME WORK
    uncomment_second_chan
#    sed -i -e "/#CHANNEL 1/ s/#CHANNEL 1/CHANNEL 1\nPTT GPIO $chan2ptt_gpio\nMODEM 1200\nMYCALL $CALLSIGN1\n/" $DIREWOLF_CFGFILE
}

# ===== function turn split channel off
function split_chan_off() {

    echo "DISable split channels, Direwolf controls left & right channels"

    sudo sed -i -e "/\[port1\]/,/\[/ s/^speed=.*/speed=1200/" $PORT_CFG_FILE
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

# Check if running as root
if [[ $EUID != 0 ]] ; then
    SYSTEMCTL="sudo systemctl"
    USER=$(whoami)
    echo "set sudo as user $USER"
fi

echo
while [[ $# -gt 0 ]] ; do

    key="$1"
    case $key in
        -d)
            echo "Set DEBUG flag"
            DEBUG=1
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

service="pulseaudio"
if systemctl is-active --quiet "$service" ; then
    stop_service $service
else
    echo "Service: $service is already stopped"
fi

config_dw_2chan
split_chan_off
# restart direwolf/ax.25
ax25-stop
ax25-start
