#!/bin/bash
# version: 1.2
#
# Display entire AX.25 configuration
#
# Uncomment this statement for debug echos
#DEBUG=1
scriptname="`basename $0`"

AX25_DEVICE_DIR="/proc/sys/net/ax25"
# AX25_KISS_CFG="/etc/systemd/system/ax25dev.service"
AX25_KISS_CFG="/etc/ax25/ax25-upd"
PORT_CFG_FILE="/etc/ax25/port.conf"
PORT_SPEED="1200"

# ===== function dbgecho

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function get_port_speed

# Needs arg of port number, either 0 or 1
# Uses port.conf file for port speed, kissattach parms & ax.25 parms

function get_port_speed() {
    retcode=0
    portnumber=$1
    if [ -z $portnumber ] ; then
        echo "Need to supply a port number in get_port_cfg"
        return 1
    fi

    portname="udr$portnumber"
    portcfg="port$portnumber"
    dbgecho "Debug: portname=$portname, portcfg=$portcfg"

    PORTSPEED=$(sed -n "/\[$portcfg\]/,/\[/p" $PORT_CFG_FILE | grep -i "^speed" | cut -f2 -d'=')
    dbgecho "AX.25: $portname speed: $PORTSPEED"

    case $PORTSPEED in
        1200 | 9600)
            dbgecho "parse baud_$PORTSPEED section for $portname"
        ;;
        off)
            echo "Using split channel, port: $portname is off"
        ;;
        *)
            echo "Invalid speed parameter: $PORTSPEED, found in $PORT_CFG_FILE"
            retcode=1
        ;;
    esac
}

# ===== function display_kissparms

function display_kissparms() {

    echo
    echo " === Display kissparms & ax25dev-parms"

    for devnum in 0 1 ; do
        # Set variables: portname, portcfg, PORTSPEED
        get_port_speed $devnum
        baudrate_parm="baud_$PORTSPEED"
        if [ "$PORTSPEED" != "off" ] && [ ! -z "$PORTSPEED" ] ; then
            SLOTTIME=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^slottime" | cut -f2 -d'=')
            TXDELAY=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^txdelay" | cut -f2 -d'=')
            TXTAIL=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^txtail" | cut -f2 -d'=')
            T1_TIMEOUT=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^t1_timeout" | cut -f2 -d'=')
            T2_TIMEOUT=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^t2_timeout" | cut -f2 -d'=')
        else
            echo "Use split channel config, HF on channel udr$devnum"
        fi
        printf "port: %d, speed: %d, slottime: %3d, txdelay: %d, txtail: %d, t1 timeout: %d, t2 timeout: %4d\n" "$devnum" "$PORTSPEED" "$SLOTTIME" "$TXDELAY" "$TXTAIL" "$T1_TIMEOUT" "$T2_TIMEOUT"
    done
    echo
    echo " == kissparms from $AX25_KISS_CFG"
    grep "KISSPARMS -p" $AX25_KISS_CFG
}

# ===== function usage

function usage() {
   echo "Usage: $scriptname [-d][-k][-h]" >&2
   echo "   -d        set debug flag"
   echo "   -k        Display kissparms only"
   echo "   -h        no arg, display this message"
   echo
}

# ===== main

# If no port config file found create one
if [ ! -f $PORT_CFG_FILE ] ; then
    echo "No port config file: $PORT_CFG_FILE found, copying from repo."
    sudo cp $HOME/n7nix/ax25/port.conf $PORT_CFG_FILE
    if [ "$?" -ne 0 ] ; then
        echo "Error copying file: port.conf ..."
    fi
fi

while [[ $# -gt 0 ]] ; do
APP_ARG="$1"

case $APP_ARG in

   -d|--debug)
      DEBUG=1
      echo "Debug mode on"
   ;;
   -k)
      display_kissparms
      exit 0
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


display_kissparms

echo
echo " ===== ax.25 config"
for dir in $AX25_DEVICE_DIR/* ; do
    echo "Found directory: $dir"
    for file in $dir/* ; do
	fname="$(basename -- "$file")"
	echo -n "$fname: "
	cat $file
    done
    echo
done

# display alsa settings
echo
alsa-show.sh

echo
echo "===== Port baudrate"
# Assume there are ONLY 2 modems configured
# in direwolf configuration file
dire_udr0_baud=$(grep -i "^MODEM " /etc/direwolf.conf | cut -d ' ' -f2 | head -n 1)
dire_udr1_baud=$(grep -i "^MODEM " /etc/direwolf.conf | cut -d ' ' -f2 | tail -n 1)
echo "DireWolf: udr0 speed: $dire_udr0_baud, udr1 speed: $dire_udr1_baud"

if [ -e $PORT_CFG_FILE ] ; then
    ax25_udr0_baud=$(sed -n '/\[port0\]/,/\[/p' $PORT_CFG_FILE | grep -i "^speed" | cut -f2 -d'=')
    ax25_udr1_baud=$(sed -n '/\[port1\]/,/\[/p' $PORT_CFG_FILE | grep -i "^speed" | cut -f2 -d'=')
    echo "AX.25:    udr0 speed: $ax25_udr0_baud, udr1 speed: $ax25_udr1_baud"
else
    echo "Port config file: $PORT_CFG_FILE NOT found."
fi

# display axports
echo
echo "===== axports"
tail -n 2 /etc/ax25/axports

# display ax25d.conf
echo
echo " ===== ax25d.conf"
CALLSIGN=$(grep -m 1 "^MYCALL" /etc/direwolf.conf | cut -d' ' -f2)
grep -A 25 -i "$CALLSIGN" /etc/ax25/ax25d.conf

# display port in wl2k.conf
echo
echo " ===== wl2k.conf"
pluax25_port=$(grep "ax25port=" /usr/local/etc/wl2k.conf)
if [[ "$pluax25_port" =~ ^#.* ]] ; then
    echo "paclink-unix not configured."
else
    echo "paclink-unix ax25 port: $pluax25_port"
fi
