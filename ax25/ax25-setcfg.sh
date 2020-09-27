#!/bin/bash
# version: 1.1
#
# ax25-setcfg.sh for experimenting with:
# TXDELAY
# TXTAIL
# SLOTTIME
# PERSIST
#
# See Section '9.2.12 Radio Channel - Transmit timing' of Direwolf
# manual (page 72)
#
# Uncomment this statement for debug echos
#DEBUG=1

# Used to qualify a numeric value
re='^[0-9]+$'

SBINDIR=/usr/local/sbin
BINDIR=/usr/local/bin
AX25_KISS_CFG="/etc/ax25/ax25-upd"

KISSPARMS="sudo $SBINDIR/kissparms"
BAUDRATE=1200
PORTNUM=0
PORTNAME_1="udr0"
b_baudset=false

PORT_CFG_FILE="/etc/ax25/port.conf"

# ===== function dbgecho

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function get_port_speed

# Needs arg of port number, either 0 or 1
# Uses port.conf file for port speed, kissattach parms & ax.25 parms

function get_port_speed() {
    # Check if baudrate is set from command line
    if [ $b_baudset = true ] ; then
        PORTSPEED=$BAUDRATE
        return
    else
        dbgecho "${FUNCNAME[0]}(): b_baudset: $b_baudset"
    fi

    retcode=0
    portnumber=$1
    if [ -z $portnumber ] ; then
        echo "Need to supply a port number in ${FUNCNAME[0]}"
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

# ===== function save_kissparms
# Set kiss parameters AND write them to a file

function save_kissparms() {

    portnumber=$1
    if [ -z $portnumber ] ; then
        echo "Need to supply a port number in ${FUNCNAME[0]}"
        return 1
    fi

    # Set variables: portname, portcfg, PORTSPEED
#    get_port_speed $portnumber
    PORTSPEED=$BAUDRATE
    baudrate_parm="baud_$PORTSPEED"

    dbgecho "DEBUG 2: port: $portnumber, speed: $PORTSPEED, slottime: $SLOTTIME, txdelay: $TXDELAY, txtail: $TXTAIL, persist: $PERSIST, t1 timeout: $T1_TIMEOUT, t2 timeout: $T2_TIMEOUT"
    dbgecho "${FUNCNAME[0]}: port: $portnumber, baud: $PORTSPEED"

    if [ "$PORTSPEED" != "off" ] && [ ! -z "$PORTSPEED" ] ; then
        echo "Saving AX.25 parameters to file $PORT_CFG_FILE"

        # slottime
        dbgecho " ${FUNCNAME[0]}(): Comparing $slottime to $SLOTTIME"
        if [ "$slottime" -ne "$SLOTTIME" ] ; then
#             sudo sed -ie "0,/^slottime/ s/^slottime=.*/slottime=$slottime/$occurence" $PORT_CFG_FILE
#             sudo sed -ie "s/^slottime=.*/slottime=$slottime/$occurence" $PORT_CFG_FILE
              if [ $PORTSPEED -eq 9600 ] ; then
                  sudo sed -ie "0,/^slottime=/!{0,/^slottime=/s/^slottime=.*/slottime=$slottime/}" $PORT_CFG_FILE
              else
                  sudo sed -ie "0,/^slottime=/{s/^slottime.*/slottime=$slottime/}" $PORT_CFG_FILE
              fi
             SLOTTIME=$slottime
        fi

        # persist
        if [ "$persist" -ne "$PERSIST" ] ; then
            if [ $PORTSPEED -eq 9600 ] ; then
                sudo sed -ie "0,/^persist=/!{0,/^persist=/s/^persist=.*/persist=$persist/}" $PORT_CFG_FILE
            else
                sudo sed -ie "0,/^persist=/{s/^persist=.*/persist=$persist/}" $PORT_CFG_FILE
            fi
            PERSIST=$persist
        fi

        # txdelay
        dbgecho "Debug: txdelay: $txdelay, TXDELAY: $TXDELAY"
        if [ "$txdelay" -ne "$TXDELAY" ] ; then
            if [ $PORTSPEED -eq 9600 ] ; then
                sudo sed -ie "0,/^txdelay=/!{0,/^txdelay=/s/^txdelay=.*/txdelay=$txdelay/}" $PORT_CFG_FILE
            else
                sudo sed -ie "0,/^txdelay/{s/^txdelay=.*/txdelay=$txdelay/}" $PORT_CFG_FILE
            fi
            TXDELAY=$txdelay
        fi

        # txtail
        dbgecho "Debug: txtail: $txtail, TXTAIL: $TXTAIL"
        if [ "$txtail" -ne "$TXTAIL" ] ; then
            if [ $PORTSPEED -eq 9600 ] ; then
                sudo sed -ie "0,/^txtail=/!{0,/^txtail=/s/^txtail=.*/txtail=$txtail/}" $PORT_CFG_FILE
            else
                sudo sed -ie "0,/^txtail/{s/^txtail=.*/txtail=$txtail/}" $PORT_CFG_FILE
            fi
            TXTAIL=$txtail
        fi

#            TXDELAY=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^txdelay" | cut -f2 -d'=')
#            TXTAIL=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^txtail" | cut -f2 -d'=')
#            T1_TIMEOUT=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^t1_timeout" | cut -f2 -d'=')
#            T2_TIMEOUT=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^t2_timeout" | cut -f2 -d'=')
    else
            echo "NO PORTSPEED found, use split channel config, HF on channel udr$portnumber"
   fi
}


# ===== function set_kissparms
# Set kiss parameters without writing them to a file

function set_kissparms() {

    portnumber=$1
    if [ -z $portnumber ] ; then
        echo "Need to supply a port number in ${FUNCNAME[0]}"
        return 1
    fi

    # Set variables: portname, portcfg, PORTSPEED
    get_port_speed $portnumber
    baudrate_parm="baud_$PORTSPEED"

    if [ "$PORTSPEED" != "off" ] && [ ! -z "$PORTSPEED" ] ; then
        if [ "$slottime" -ne "$SLOTTIME" ] ; then
#            sudo sed -ie "0,/^slottime/ s/^slottime=.*/slottime=$slottime/" $PORT_CFG_FILE
             SLOTTIME=$slottime
        fi

        if [ "$persist" -ne "$PERSIST" ] ; then
#            sudo sed -ie "0,/^persist/ s/^persist=.*/persist=$persist/" $PORT_CFG_FILE
            PERSIST=$persist
        fi
        dbgecho "Debug: txdelay: $txdelay, TXDELAY: $TXDELAY"
        if [ "$txdelay" -ne "$TXDELAY" ] ; then
            TXDELAY=$txdelay
        fi

        dbgecho "Debug: txtail: $txtail, TXTAIL: $TXTAIL"
        if [ "$txtail" -ne "$TXTAIL" ] ; then
            TXTAIL=$txtail
        fi

#            TXDELAY=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^txdelay" | cut -f2 -d'=')
#            TXTAIL=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^txtail" | cut -f2 -d'=')
#            T1_TIMEOUT=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^t1_timeout" | cut -f2 -d'=')
#            T2_TIMEOUT=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^t2_timeout" | cut -f2 -d'=')
    else
            echo "NO PORTSPEED found, use split channel config, HF on channel udr$portnumber"
   fi
}

# ===== function get_kissparms

function get_kissparms() {

    portnumber=$1

    # Set variables: portname, portcfg, PORTSPEED
    PORTSPEED=$BAUDRATE
    if [ $b_baudset = false ] ; then
        get_port_speed $portnumber
    fi
    baudrate_parm="baud_$PORTSPEED"
    dbgecho "Getting kissparms for port speed: $PORTSPEED"

    if [ "$PORTSPEED" != "off" ] && [ ! -z "$PORTSPEED" ] ; then
        SLOTTIME=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^slottime" | cut -f2 -d'=')
        TXDELAY=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^txdelay" | cut -f2 -d'=')
        TXTAIL=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^txtail" | cut -f2 -d'=')
        PERSIST=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^persist" | cut -f2 -d'=')
        T1_TIMEOUT=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^t1_timeout" | cut -f2 -d'=')
        T2_TIMEOUT=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^t2_timeout" | cut -f2 -d'=')
    else
        echo "NO PORTSPEED found, use split channel config, HF on channel udr$portnumber"
    fi
}

# ===== function display_kissparms

function display_kissparms() {

    portnumber=$1
    if [ -z $portnumber ] ; then
        echo "Need to supply a port number in ${FUNCNAME[0]}"
        return 1
    fi

    # Set variables: portname, portcfg, PORTSPEED
    PORTSPEED=$BAUDRATE
    if [ $b_baudset = false ] ; then
        get_port_speed $portnumber
    fi

    baudrate_parm="baud_$PORTSPEED"

    if [ "$PORTSPEED" != "off" ] && [ ! -z "$PORTSPEED" ] ; then
        SLOTTIME=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^slottime" | cut -f2 -d'=')
        TXDELAY=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^txdelay" | cut -f2 -d'=')
        TXTAIL=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^txtail" | cut -f2 -d'=')
        PERSIST=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^persist" | cut -f2 -d'=')
        T1_TIMEOUT=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^t1_timeout" | cut -f2 -d'=')
        T2_TIMEOUT=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^t2_timeout" | cut -f2 -d'=')
    else
        echo "Use split channel config, HF on channel udr$portnumber"
    fi
    printf "port: %d, speed: %d, slottime: %3d, txdelay: %d, txtail: %3d, persist: %d, t1 timeout: %d, t2 timeout: %4d\n" "$portnumber" "$PORTSPEED" "$SLOTTIME" "$TXDELAY" "$TXTAIL" "$PERSIST" "$T1_TIMEOUT" "$T2_TIMEOUT"
}

# function init_kissparms
function init_kissparms() {
    get_kissparms $PORTNUM
    persist=$PERSIST
    slottime=$SLOTTIME
    txdelay=$TXDELAY
    txtail=$TXTAIL
}

# ===== function usage

function usage() {
   echo "Usage: $scriptname [-d][-k][-s][-h][[--port <val>][--baudrate <val>][--persist <val>][--slottime <val>][--txdelay <val>][--txtail <val>]" >&2
   echo " default Direwolf parameters:"
   echo " --slottime 10, --persist 63, --txdelay 30, --txtail 10"
   echo "   -d          set debug flag"
   echo "   -k          Display kissparms only"
   echo "   -s          Save parameters to a file"
   echo "   -h          Display this message"
   echo "   --port <val>      Select port number (0 - left, 1 - right) default 0"
   echo "   --baudrate <val>  Set baudrate (1200 or 9600) default 1200"
   echo "   --persist <val>   Set persist (0-255)"
   echo "   --slottime <val>  Set slottime in mSec (0-500, steps of 10 mSec)"
   echo "   --txdelay <val>   Set txdelay in mSec(0-500, steps of 10 mSec)"
   echo "   --txtail <val>    Set txtail in mSec (0-500, steps of 10 mSec)"
   echo
}


# ===== main

init_kissparms

dbgecho "DEBUG 1: port: $portnumber, speed: $PORTSPEED, slottime: $SLOTTIME, txdelay: $TXDELAY, txtail: $TXTAIL, persist: $PERSIST, t1 timeout: $T1_TIMEOUT, t2 timeout: $T2_TIMEOUT"

while [[ $# -gt 0 ]] ; do
APP_ARG="$1"

case $APP_ARG in

    -d|--debug)
        DEBUG=1
        echo "Debug mode on"
    ;;
    -k)
        b_baudset=true
        BAUDRATE=1200
        display_kissparms $PORTNUM
        BAUDRATE=9600
        display_kissparms $PORTNUM
        exit 0
   ;;
    -s)
        set_kissparms $PORTNUM
        save_kissparms $PORTNUM
        exit 0
   ;;
   --port)
        # value range 0 or 1
        portnum=$2
        shift  # past argument

        if ! [[ $portnum =~ $re ]] ; then
            echo "error: $portnum NOT a number" >&2
            exit 1
        fi
        if (( $portnum != 0 )) && (( $portnum != 1 )) ; then
            echo "Error: invalid port number $portnum, must be either 0 or 1"
            exit 1
        fi
        echo "setting port number to: $portnum"
        if [[ $portnum -ne "$PORTNUM" ]] ; then
            PORTNUM=$portnum
        fi
   ;;
   --baud)
        # value range 1200 or 9600
        baudrate=$2
        shift  # past argument

        if ! [[ $baudrate =~ $re ]] ; then
            echo "error: $baudrate NOT a number" >&2
            exit 1
        fi
        if (( $baudrate != 1200 )) && (( $baudrate != 9600 )) ; then
            echo "Error: invalid baudrate value $baudrate, must be either 1200 or 9600"
            exit 1
        fi
        echo "setting baudrate to: $baudrate"
        b_baudset=true
        dbgecho "${FUNCNAME[0]}(): baudset: $b_baudset"

        if [[ $baudrate -ne "$BAUDRATE" ]] ; then
            BAUDRATE=$baudrate
            init_kissparms
        fi
   ;;
   --persist)
        # Value % scaled to range 0 - 255
        persist=$2
        shift  # past argument

        if ! [[ $persist =~ $re ]] ; then
            echo "error: $persist NOT a number" >&2
            exit 1
        fi
        if (( $persist >= 0 )) && (( $persist <= 255 )) ; then
            echo "setting PERSIST to: $persist"
        else
            echo "Error: invalid PERSIST value $persist, must be 0-100"
            exit 1
        fi
   ;;
   --slottime)
        # Value in milliseconds, range 0 - 500
        slottime=$2
        shift  # past argument
        if ! [[ $slottime =~ $re ]] ; then
            echo "error: $slottime NOT a number" >&2
            exit 1
        fi

        #steps of 10 mSec only
        slottime_10=$(( (slottime/10) * 10 ))

        dbgecho "Compare slottime: $slottime, to slottime_10: $slottime_10"
        if (( slottime_10 != slottime )) ; then
            echo "Slottime($slottime): must be a multiple of 10: $slottime_10"
            slottime=$slottime_10;
        fi

        if (( $slottime >= 0 )) && (( $slottime <= 500 )) ; then
            echo "setting SLOTTIME to: $slottime, for baudrate: $BAUDRATE"
        else
            echo "Error: invalid SLOTTIME value $slottime, must be 0-500"
            exit 1
        fi
   ;;
   --txdelay)
       txdelay=$2
       shift  # past argument
        if ! [[ $txdelay =~ $re ]] ; then
            echo "error: $txdelay NOT a number" >&2
            exit 1
        fi

        #steps of 10 mSec only
        txdelay_10=$(( (txdelay/10) * 10 ))

        if (( txdelay_10 != txdelay )) ; then
            echo "Txdelay: must be a multiple of 10: $txdelay"
            txdelay=$txdelay_10;
        fi

        if (( $txdelay >= 0 )) && (( $txdelay <= 700 )) ; then
            echo "setting TXDELAY to: $txdelay"
        else
            echo "Error: invalid TXDELAY value $txdelay, must be 0-500"
            exit 1
        fi
   ;;
   --txtail)
       txtail=$2
       shift  # past argument
        #steps of 10 mSec only
        txtail=$(( (txtail/10) * 10 ))
        if ! [[ $txtail =~ $re ]] ; then
            echo "error: $txtail NOT a number" >&2
            exit 1
        fi
        if (( $txtail >= 0 )) && (( $txtail <= 700 )) ; then
            echo "setting TXTAIL to: $txtail"
        else
            echo "Error: invalid TXTAIL value $txtail, must be 0-500"
            exit 1
        fi
   ;;
   -h|--help|?)
      usage
      exit 0
   ;;
   *)
      echo "Unrecognized argument: $APP_ARG"
      exit 1
   ;;

esac

shift # past argument
done

set_kissparms $PORTNUM
display_kissparms $PORTNUM

# Set kissparms

printf "KISSPARMS set to:\nport: %d, speed: %d, slottime: %3d, txdelay: %d, txtail: %d, persist: %d, t1 timeout: %d, t2 timeout: %4d\n" "$portnumber" "$PORTSPEED" "$SLOTTIME" "$TXDELAY" "$TXTAIL" "$PERSIST" "$T1_TIMEOUT" "$T2_TIMEOUT"

$KISSPARMS -p ${portname} -f no -l $TXTAIL -r $PERSIST -s $SLOTTIME -t $TXDELAY