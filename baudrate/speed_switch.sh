#!/bin/bash
# version: 1.1
#
# Switch for 1200 baud and 9600 baud packet speed
#
DEBUG=
USER=$(whoami)
scriptname="`basename $0`"

BIN_PATH="/home/$USER/bin"

PORT_CFG_FILE="/etc/ax25/port.conf"
DIREWOLF_CFGFILE="/etc/direwolf.conf"

# ===== function dbgecho

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }


# ===== function get_port_speed

# Needs arg of port number, either 0 or 1
# Uses port.conf file for:
#  - port speed, kissattach parms & ax.25 parms
#  - enabling split channel

function get_port_speed() {
    retcode=0
    if [ -e $PORT_CFG_FILE ] ; then
        dbgecho " ax25 port file exists"
        portnumber=$1
        if [ -z $portnumber ] ; then
            echo "Need to supply a port number in get_port_speed"
            return 1
        fi

        portname="udr$portnumber"
        portcfg="port$portnumber"

#        echo "Debug: portname=$portname, portcfg=$portcfg"

        PORTSPEED=$(sed -n "/\[$portcfg\]/,/\[/p" $PORT_CFG_FILE | grep -i "^speed" | cut -f2 -d'=')
        dbgecho "AX.25: $portname speed: $PORTSPEED"

        case $PORTSPEED in
            1200)
                dbgecho "parse baud_1200 section for $portname"
            ;;
            9600)
                dbgecho "parse baud_9600 section for $portname"
            ;;
            off)
                echo "Using split channel, port: $portname is off"
            ;;
            *)
                echo "Invalid speed parameter: $PORTSPEED, found in $PORT_CFG_FILE"
                retcode=1
            ;;
        esac
    else
        echo "ax25 port file: $PORT_CFG_FILE does not exist"
        retcode=1
    fi
    return $retcode
}

# ===== function speed_status

# Display parameters used for kissattach & AX.25 device

function speed_status() {

    SLOTTIME=
    TXDELAY=
    T1_TIMEOUT=
    T2_TIMEOUT=
    declare -A devicestat=([ax0]="exists" [ax1]="exists")

    # Check if direwolf is already running.
    pid=$(pidof direwolf)
    if [ $? -eq 0 ] ; then
        echo "Direwolf is running with pid of $pid"
    else
        echo "Direwolf is NOT running"
    fi

    for devnum in 0 1 ; do
        # Set variables: portname, portcfg, PORTSPEED
        get_port_speed $devnum
        baudrate_parm="baud_$PORTSPEED"
        if [ "$PORTSPEED" != "off" ] && [ ! -z "$PORTSPEED" ] ; then
            SLOTTIME=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^slottime" | cut -f2 -d'=')
            TXDELAY=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^txdelay" | cut -f2 -d'=')
        fi

        devname="ax$devnum"
        PARMDIR="/proc/sys/net/ax25/$devname"
        if [ -d "$PARMDIR" ] ; then
            dbgecho "Parameters for device $devname"

            T1_TIMEOUT=$(cat $PARMDIR/t1_timeout)
            T2_TIMEOUT=$(cat $PARMDIR/t2_timeout)
        else
            devicestat[$devname]="does NOT exist"
        fi
        echo "port: $devnum, speed: $PORTSPEED, slottime: $SLOTTIME, txdelay: $TXDELAY, t1 timeout: $T1_TIMEOUT, t2 timeout: $T2_TIMEOUT"
    done
    # Use a single line for device status
    echo "Device: ax0 ${devicestat[ax0]}, Device: ax1 ${devicestat[ax1]}"
}

# ===== function direwolf_set_baud

# Set baud rate on MODEM line for the first modem channel

function direwolf_set_baud() {

    modem_speed="$1"

    echo "=== set $DIREWOLF_CFGFILE baud rate to: $modem_speed"

    # Modify first occurrence of MODEM configuration line
    sudo sed -i "0,/^MODEM/ s/^MODEM .*/MODEM $modem_speed/" $DIREWOLF_CFGFILE

    # Modify second occurrence of MODEM configuration line
    # sudo sed -i -e "0,/^MODEM /! {/^MODEM/ s/^MODEM .*/MODEM $modem_speed/}" $DIREWOLF_CFGFILE

    # Modify both occurrences of MODEM configuration line
    # sudo sed -i "/^MODEM/ s/^MODEM .*/MODEM $modem_speed/" $DIREWOLF_CFGFILE
}

# ==== function set_baudrate
# Requires 3 arguments:
#   port number (0 or 1),
#   baudrate (1200 or 9600),
#   receive output (either audio or disc)

function set_baudrate() {
    portnum="$1"
    baudrate="$2"
    receive_out="$3"

    echo "=== set $PORT_CFG_FILE baud rate to: $baudrate"
    # Switch speeds in port config file
    sudo sed -i -e "/\[port$portnum\]/,/\[/ s/^speed=.*/speed=$baudrate/" $PORT_CFG_FILE
    # Set audio/disc in port config file
    sudo sed -i -e "/\[port$portnum\]/,/\[/ s/^receive_out=.*/receive_out=$receive_out/" $PORT_CFG_FILE

    direwolf_set_baud $baudrate
}
# function get_baudrates
function get_baudrates() {
    # Initialize baud rates for each device
    ax25_udr0_baud=0
    ax25_udr1_baud=0

    if [ -e $PORT_CFG_FILE ] ; then
        ax25_udr0_baud=$(sed -n '/\[port0\]/,/\[/p' $PORT_CFG_FILE | grep -i "^speed" | cut -f2 -d'=')
        ax25_udr1_baud=$(sed -n '/\[port1\]/,/\[/p' $PORT_CFG_FILE | grep -i "^speed" | cut -f2 -d'=')
        dbgecho "AX.25: udr0 speed: $ax25_udr0_baud, udr1 speed: $ax25_udr1_baud"
    else
        echo "Port config file: $PORT_CFG_FILE NOT found."
        return;
    fi
}

# ===== function switch_config

# Switch a single port based upon config file setting.
# NOTE: only switches port 0

function switch_config() {

    get_baudrates

    case "$ax25_udr0_baud" in
        1200)
            newspeed_port0=9600
            # For reference only
            newreceive_out0=disc
        ;;
        9600)
            newspeed_port0=1200
            # For reference only
            newreceive_out0=disc
        ;;
        off)
            newspeed=off
        ;;
        *)
            echo "Invalid speed parameter: $ax25_udr0_baud"
            return;
        ;;
    esac
    # port number, speed (1200/9600) receive_out (audio/disc)
    set_baudrate 0 $newspeed_port0 $newreceive_out0

}


# ===== function usage

function usage() {
   echo "Usage: $scriptname [-b <speed>][-s][-d][-h]" >&2
   echo " Default to toggling baud rate when no command line arguments found."
   echo "   -b | --baudrate <baudrate>  Set baud rate speed, 1200 or 9600"
   echo "   -s | --status          Display current status of devices & ports"
   echo "   -d | --debug           Set debug flag for verbose output"
   echo "   -h | --help            Display this message"
   echo
}

# ===== main

# Be sure NOT running as root
if [[ $EUID == 0 ]] ; then
   echo "Must NOT be root"
   exit 1
fi
USER=$(whoami)

# If no port config file found create one
if [ ! -f $PORT_CFG_FILE ] ; then
    echo "No port config file: $PORT_CFG_FILE found, copying from repo."
    sudo cp $HOME/n7nix/ax25/port.conf $PORT_CFG_FILE
fi

while [[ $# -gt 0 ]] ; do
    APP_ARG="$1"

    case $APP_ARG in
        -s|--status|status)
            echo " === AX.25 baudrate status"
            speed_status
            exit 0
        ;;
        -b|--baudrate)
            baudrate="$2"
            shift  # past argument
            # set variables ax25_udr0_baud, ax25_udr1_baud=0

            get_baudrates
            dbgecho " === set baudrate to: $baudrate"
            if [ "$baudrate" = "$ax25_udr0_baud" ] && [ $(pidof direwolf) ] ; then
                echo " === baud rate already set to $baudrate & direwolf is running"
                exit 0
            fi

            # default receive to discriminator
            # port number, speed (1200/9600) receive_out (audio/disc)
            set_baudrate 0 $baudrate "disc"

            # Check if direwolf is already running.
            pid=$(pidof direwolf)
            if [ $? -eq 0 ] ; then
                echo "Direwolf is running with pid of $pid"
            else
                echo "Direwolf is NOT running. Starting NOW ..."
                $BIN_PATH/ax25-start -q
            fi

            exit 0
        ;;
        -d|--debug)
            echo "Verbose output"
            DEBUG=1
       ;;
       -h|--help|?)
            usage
            exit 0
       ;;
       *)
            break;
       ;;
    esac

    shift # past argument
done

# default to toggling baud rate between 1200 & 9600
switch_config

# DEBUG ONLY
echo "Verify port.conf"
grep -i "^speed" $PORT_CFG_FILE
echo
echo "Verify $DIREWOLF_CFGFILE"
speed_cnt=$(grep "^MODEM" $DIREWOLF_CFGFILE | wc -l)
if [ $speed cnt > 0 ] && [ $speed_cnt <= 2 ] ; then
    dbgecho "There are $speed_cnt instances of MODEM speed."
else
    echo "Error: Wrong count of MODEM speed instances: $speed_cnt"

fi
grep -i "^MODEM" $DIREWOLF_CFGFILE

echo
echo "=== set alsa config"
if [ -z "$DEBUG" ] ; then
    sudo $BIN_PATH/setalsa-tmv71a.sh > /dev/null 2>&1
else
    # Verbose output
    sudo $BIN_PATH/setalsa-tmv71a.sh
fi

echo
echo "=== reset direwolf & ax25 parms"
$BIN_PATH/ax25-reset.sh -q