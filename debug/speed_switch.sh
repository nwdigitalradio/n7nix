#!/bin/bash
#
# Switch for 1200 baud and 9600 baud packet speed
#
DEBUG=

USER=$(whoami)
BIN_PATH="/home/$USER/bin"

SWITCH_FILE="/etc/ax25/packet_9600baud"
PORT_CFG_FILE="/etc/ax25/port.conf"
DIREWOLF_CFGFILE="/etc/direwolf.conf"

# ===== function dbgecho

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }


# ===== function check_port_file
# Needs arg of port number, either 0 or 1

function get_port_cfg() {
    retcode=0
    if [ -e $PORT_CFG_FILE ] ; then
        dbgecho " ax25 port file exists"
        portnumber=$1
        if [ -z $portnumber ] ; then
            echo "Need to supply a port number in get_port_cfg"
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
            none)
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

# ===== function check_switch_file

function check_switch_file() {
    if [ -e "$SWITCH_FILE" ] ; then
        echo "Baudrate Switch file exists"
        # Anything in the file?
        if [ -s "$SWITCH_FILE" ] ; then
            # Check for speed_chan
            echo "File: $SWITCH_FILE NOT empty"
        else
            echo "Nothing in file: $SWITCH_FILE"
        fi
    else
        echo "Baudrate Switch file does NOT exist"
    fi
}

# ===== function speed_status

function speed_status() {

    SLOTTIME=
    TXDELAY=
    T1_TIMEOUT=
    T2_TIMEOUT=

    check_switch_file

    echo
    echo " === Display ax25dev-parms"

    for devnum in 0 1 ; do
        # Set variables: portname, portcfg, PORTSPEED
        get_port_cfg $devnum
        baudrate_parm="baud_$PORTSPEED"
        if [ "$PORTSPEED" != "none" ] && [ ! -z "$PORTSPEED" ] ; then
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
            echo "Device: $devname does NOT exist"
        fi
        echo "port: $devnum, speed: $PORTSPEED, slottime: $SLOTTIME, txdelay: $TXDELAY, t1 timeout: $T1_TIMEOUT, t2 timeout: $T2_TIMEOUT"

    done
}

# ===== function usage

function usage() {
   echo "Usage: $scriptname [-s]" >&2
   echo "   -s      Display current status of speed."
   echo "   -d      Set flag for verbose output"
   echo "   -h      Display this message"
   echo
}

# ===== main

while [[ $# -gt 0 ]] ; do
APP_ARG="$1"

case $APP_ARG in

   -s)
      echo " === AX.25 parameter status"
      speed_status
      exit 0
   ;;
   -d)
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



if [ -e "$SWITCH_FILE" ] ; then
    # For 1200 baud packet
    echo
    echo "Removing 9600 baud speed switch file"
    echo
    sudo rm $SWITCH_FILE
    echo "rm ret code: $?"
    if [ -e "$SWITCH_FILE" ] ; then
        echo "switch failed, $SWITCH_FILE still exists"
        exit 1
    fi

    echo
    echo "=== set direwolf 1200 baud speed"

    # uncomment 1200 baud line
    sudo sed -i '/^#MODEM 1200/ s/^#//' $DIREWOLF_CFGFILE

    # Comment out any 9600 lines
    sudo sed -i -e "/^MODEM 9600/ s/^/#/" $DIREWOLF_CFGFILE

else
    # For 9600 baud packet
    echo
    echo "Creating speed 9600 baud switch file"
    echo
    sudo touch $SWITCH_FILE
    echo "touch ret code: $?"

    echo
    echo "=== set direwolf 9600 baud speed"
    # uncomment 9600 baud line
    sudo sed -i '/^#MODEM 9600/ s/^#//' $DIREWOLF_CFGFILE

    # Comment out any 1200 lines
    sudo sed -i -e "/^MODEM 1200/ s/^/#/" $DIREWOLF_CFGFILE
fi

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
$BIN_PATH/ax25-reset.sh
