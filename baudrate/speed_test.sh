#!/bin/bash
#
# Switch continous test for 1200 baud and 9600 baud packet speed
DEBUG=

USER=$(whoami)
#BIN_PATH="/home/$USER/n7nix/debug"
BIN_PATH="/home/$USER/bin"
PORT_CFG_FILE="/etc/ax25/port.conf"

# For display to console
TEE_CMD="sudo tee -a $DW_TT_LOG_FILE"

# For logging to log file only!
# If you do not suppress stdout, direwolf will output it to radio in
# Morse Code.
#TEE_CMD="sudo dd status=none of=$DW_TT_LOG_FILE oflag=append conv=notrunc"


# ===== function debugecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function get_port_speed

# Needs arg of port number, either 0 or 1
# Uses port.conf file for:
#  - port speed, kissattach parms & ax.25 parms
#  - enabling split channel

get_port_speed() {
    retcode=0
    if [ -e $PORT_CFG_FILE ] ; then
        portnumber=$1
        dbgecho " ax25 port file exists, port: $portnumber"
        if [ -z $portnumber ] ; then
            echo "Need to supply a port number in get_port_speed" | $TEE_CMD
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
                echo "Using split channel, port: $portname is off" | $TEE_CMD
            ;;
            *)
                echo "Invalid speed parameter: $PORTSPEED, found in $PORT_CFG_FILE" | $TEE_CMD
                retcode=1
            ;;
        esac
    else
        echo "ax25 port file: $PORT_CFG_FILE does not exist" | $TEE_CMD
        retcode=1
    fi
    return $retcode
}

# ===== function speed_status

# Display parameters used for kissattach & AX.25 device

speed_status() {

    SLOTTIME=
    TXDELAY=
    T1_TIMEOUT=
    T2_TIMEOUT=
    DEVWAIT=15

#    declare -A devicestat=([ax0]="exists" [ax1]="exists")
    devicestat0="exists"
    devicestat1="exists"

    # Check if direwolf is already running.
    pid=$(pidof direwolf)
    if [ $? -eq 0 ] ; then
        dbgecho "$(date): ${FUNCNAME[0]}: Direwolf is running with pid of $pid" | $TEE_CMD
    else
        echo "Direwolf is NOT running" | $TEE_CMD
    fi

#    for devnum in 0 1 ; do
        devnum=0
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
            dbgecho "Dir OK: $PARMDIR. Parameters for device $devname"

            T1_TIMEOUT=$(cat $PARMDIR/t1_timeout)
            T2_TIMEOUT=$(cat $PARMDIR/t2_timeout)
        else
#            devicestat[$devname]="does NOT exist"
             eval devicestat_tmp="\"devicestat$devnum\""
	     safevar="$devname does NOT exist"
             eval $devicestat_tmp=\$safevar
        fi
        echo "Device: $devnum, speed: $PORTSPEED, slottime: $SLOTTIME, txdelay: $TXDELAY, t1 timeout: $T1_TIMEOUT, t2 timeout: $T2_TIMEOUT"
#    done
    t1_set=3000
    t2_set=1000
    if [ $PORTSPEED -eq 9600 ] ; then
        t1_set=2000
	t2_set=100
    fi
    if [ -z $T1_TIMEOUT ] || [ -z $T2_TIMEOUT ] || [ $T1_TIMEOUT -ne $t1_set ] || [ $T2_TIMEOUT -ne $t2_set ] ; then
        echo
        echo "$(tput setaf 1)Error setting ax25 timeouts$(tput sgr0)"
	# Hack
	sudo /etc/ax25/ax25dev-parms ax0 $PORTSPEED
    fi


    # Use a single line for device status
#    echo "Device: ax0 ${devicestat[ax0]}, Device: ax1 ${devicestat[ax1]}"
    echo "Device: ax0 ${devicestat0}, Device: ax1 ${devicestat1}"
}

# ===== function wait_compare
# arg1: baudrate either 1200 or 9600
# Wait until /proc/sys/net/ax25 value matches value in port.conf

function wait_compare() {

    brate=$1

    # Set retcode to compare fail
    retcode=1

    # Get T1_TIME from port.conf file
    baudrate_parm="baud_$1"
    port_t1time=$(sed -n "/\[$baudrate_parm\]/,/\[/p" $PORT_CFG_FILE | grep -i "^t1_timeout" | cut -f2 -d'=')

    # Get T1_TIME from /proc/sys/net/ax25/ax0/t1_timeout
    devnum=0
    devname="ax$devnum"
    PARMDIR="/proc/sys/net/ax25/$devname"

    # DEBUG
    T1_TIMEOUT=$(cat $PARMDIR/t1_timeout)
    echo "wait_compare: proc: $T1_TIMEOUT, port: $port_t1time"

    begin_sec=$SECONDS
    T1_TIMEOUT=

    while [ $((SECONDS-begin_sec)) -lt 25 ] ; do
        if [ -d "$PARMDIR" ] && [ -f "$PARMDIR/t1_timeout" ] ; then

	    # T1_TIMEOUT=
            T1_TIMEOUT=$(cat $PARMDIR/t1_timeout 2>/dev/null)
	    catret=$?
	    if [ $catret -ne 0 ] ; then
	        # echo "wait_compare(): ret: $catret"
		continue;
	    fi
	    # echo "cat retcode: $?"
            # T2_TIMEOUT=$(cat $PARMDIR/t2_timeout)
	else
	    continue
        fi

	if [ ! -z $T1_TIMEOUT ] && [ "$T1_TIMEOUT" -eq "$port_t1time" ] ; then
	    retcode=0
	    break;
	fi

    done

    return $retcode
}

# ===== main

USER=$(whoami)
LOCAL_BIN_PATH="/home/$USER/bin"

brate=1200

itercnt=0
# while : ; do
while [[ $itercnt -lt 20 ]] ; do
    start_sec=$SECONDS
    $LOCAL_BIN_PATH/speed_switch.sh -b $brate
    echo "Finished speed_switch: ret $?"

    # Compare port.conf file t1_timeout to
    # /proc/sys/net/ax25/ax0/t1_timeout value
    wait_compare $brate
    if [ $? -eq 1 ] ; then
        echo "TIMEOUT waiting for compare"
	exit
    fi

    speed_status

    (( itercnt++ ))
    echo "$(tput setaf 6)Iteration: $itercnt, elapsed time:  $((SECONDS-start_sec)) $(tput sgr0)"
    if [ $brate -eq 1200 ] ; then
	brate=9600
    else
        brate=1200
    fi
done
exit 0
