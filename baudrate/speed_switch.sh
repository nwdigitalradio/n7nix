#!/bin/bash
# version: 1.1
#
# Switch for 1200 baud and 9600 baud packet speed
# When called
#
DEBUG=
QUIET=
USER=
set_baudrate_flag=false

scriptname="`basename $0`"


PORT_CFG_FILE="/etc/ax25/port.conf"
DIREWOLF_CFGFILE="/etc/direwolf.conf"
DW_TT_LOG_FILE="/var/log/direwolf/dw-log.txt"
DW_LOG_FILE="/var/log/direwolf/direwolf.log"

# For display to console
#TEE_CMD="sudo tee -a $DW_TT_LOG_FILE"

# For logging to log file only!
# If you do not suppress stdout, direwolf will output it to radio in
# Morse Code.
TEE_CMD="sudo dd status=none of=$DW_TT_LOG_FILE oflag=append conv=notrunc"


# ===== function dbgecho

# if DEBUG is defined then echo
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*" | $TEE_CMD; fi }

# if QUIET is defined then DO NOT echo
function quietecho { if [ -z "$QUIET" ] ; then echo "$*"; fi }

# ===== function get_user
# When running as root need to find a valid local bin directory
# Set USER based on finding a REQUIRED_PROGRAM

function get_user() {
    # Check if there is only a single user on this system
    if (( `ls /home | wc -l` == 1 )) ; then
        USER=$(ls /home)
    else
        USER=
        # Get here when there is more than one user on this system,
        # find the local bin that has the requested program

        REQUIRED_PROGRAM="ax25-restart"

        for DIR in $(ls /home | tr '\n' ' ') ; do
             if [ -d "/home/$DIR" ] && [ -e "/home/$DIR/bin/$REQUIRED_PROGRAM" ] ; then
                USER="$DIR"
                dbgecho "DEBUG: found dir: /home/$DIR & /home/$DIR/bin/$REQUIRED_PROGRAM"

                break
            fi
        done
    fi
}

# ==== function check_user
# Verify user name passed on command line is legit

function check_user() {
   userok=false
   dbgecho "$scriptname: Verify user name: $USER"
   for username in $USERLIST ; do
      if [ "$USER" = "$username" ] ; then
         userok=true;
      fi
   done

   if [ "$userok" = "false" ] ; then
      echo "$scriptname: ERROR: User name ($USER) does not exist,  must be one of: $USERLIST" | $TEE_CMD
      exit 1
   fi

   dbgecho "using USER: $USER"
}

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

function speed_status() {

    SLOTTIME=
    TXDELAY=
    T1_TIMEOUT=
    T2_TIMEOUT=
    declare -A devicestat=([ax0]="exists" [ax1]="exists")

    # Check if direwolf is already running.
    pid=$(pidof direwolf)
    if [ $? -eq 0 ] ; then
        dbgecho "$(date): ${FUNCNAME[0]}: Direwolf is running with pid of $pid" | $TEE_CMD
    else
        echo "Direwolf is NOT running" | $TEE_CMD
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

# ===== function dw_speed_cnt

function dw_speed_cnt() {
    speed_cnt=$(grep "^MODEM" $DIREWOLF_CFGFILE | wc -l)
    if (( speed_cnt > 0 )) && (( speed_cnt <= 2 )) ; then
        dbgecho "There are $speed_cnt instances of MODEM speed."
    else
        echo "Error: Wrong count of MODEM speed instances: $speed_cnt" | $TEE_CMD
    fi
}

# ===== function direwolf_set_baud

# Set baud rate on MODEM line for the first modem channel

function direwolf_set_baud() {

    modem_speed="$1"

    echo "$(date): set $DIREWOLF_CFGFILE baud rate to: $modem_speed" | $TEE_CMD

    # Modify first occurrence of MODEM configuration line
    sudo sed -i "0,/^MODEM/ s/^MODEM .*/MODEM $modem_speed/" $DIREWOLF_CFGFILE

    # Modify second occurrence of MODEM configuration line
    # sudo sed -i -e "0,/^MODEM /! {/^MODEM/ s/^MODEM .*/MODEM $modem_speed/}" $DIREWOLF_CFGFILE

    # Modify both occurrences of MODEM configuration line
    # sudo sed -i "/^MODEM/ s/^MODEM .*/MODEM $modem_speed/" $DIREWOLF_CFGFILE

    # Verify number of instances of MODEM, which sets baud rate in
    # direwolf
    dw_speed_cnt
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

    echo "$(date): set $PORT_CFG_FILE baud rate to: $baudrate" | $TEE_CMD
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
        echo "Port config file: $PORT_CFG_FILE NOT found." | $TEE_CMD
        return;
    fi
}

# ===== function baudrate_toggle
# toggle baud rate between 1200 & 9600

function baudrate_toggle() {

    switch_config

    # DEBUG ONLY
    if [ ! -z "$DEBUG" ] ; then
        echo "Verify $PORT_CFG_FILE" | $TEE_CMD
        grep -i "^speed" $PORT_CFG_FILE
        echo
        echo "Verify $DIREWOLF_CFGFILE" | $TEE_CMD
        dw_speed_cnt

        grep -i "^MODEM" $DIREWOLF_CFGFILE
    fi
}

# ===== function baudrate_config
function baudrate_config() {
    # set variables ax25_udr0_baud, ax25_udr1_baud=0

    get_baudrates
    dbgecho " === set baudrate to: $baudrate"
    if [ "$baudrate" = "$ax25_udr0_baud" ] && [ $(pidof direwolf) ] ; then
        echo " === baud rate already set to $baudrate & direwolf is running" | $TEE_CMD
        exit 0
    fi

    # default receive to discriminator
    # port number, speed (1200/9600) receive_out (audio/disc)
    set_baudrate 0 $baudrate "disc"
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
            echo "Invalid speed parameter: $ax25_udr0_baud" | $TEE_CMD
            return;
        ;;
    esac
    # port number, speed (1200/9600) receive_out (audio/disc)
    set_baudrate 0 $newspeed_port0 $newreceive_out0

}
# ===== function parent_check
function parent_check() {
    retcode=0
    # direwolf will not allocate a tty to spawned script
    if [ -t 0 ] ; then
        echo "running from a console" | $TEE_CMD
    else
        # Get parent pid of parent
        PPPID=$(ps h -o ppid= $PPID)
        # get name of the command
        P_COMMAND=$(ps h -o %c $PPPID)

        echo "running from: $P_COMMAND" | $TEE_CMD
        retcode=1
    fi
    return $retcode
}

# ===== function reset_stack
function reset_stack() {
    QUIET="-q"

    echo "reset_stack arg: $1"  | $TEE_CMD
    # If running from direwolf then wait for the morse code response
    if [ "$1" -eq 1 ] ; then
        wait4morse=$(tail -n 5 $DW_LOG_FILE| grep -i "\[0.morse\]")
        start_sec=$SECONDS
        while [[ $wait4morse -ne 0 ]] ; do
            wait4morse=$(tail -n 5 $DW_LOG_FILE| grep -i "\[0.morse\]")
        done
        echo "Would do a direwolf reset now after $((SECONDS-startsec)) seconds" | $TEE_CMD
#       at now + 1 min -f /home/pi/bin/ax25-restart
        # This used for time second resolution using 'at' command
        at -t $(date --date="now +5 seconds" +"%Y%m%d%H%M.%S") -f /home/pi/bin/ax25-restart  > /dev/null 2>&1
    fi

    echo "Exit reset_stack after $((SECONDS-startsec)) seconds" | $TEE_CMD
}

# ===== function usage

function usage() {
   echo "Usage: $scriptname [-b <speed>][-s][-d][-h][USER]" >&2
   echo " Default to toggling baud rate when no command line arguments found."
   echo "   -b | --baudrate <baudrate>  Set baud rate speed, 1200 or 9600"
   echo "   -s | --status          Display current status of devices & ports"
   echo "   -d | --debug           Set debug flag for verbose output"
   echo "   -h | --help            Display this message"
   echo
}

# ===== main

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
            set_baudrate_flag=true
        ;;
        -q|--quiet)
            QUIET=1
       ;;
        -d|--debug)
            echo "Verbose output"
            DEBUG=1
       ;;
       -h|--help|-?|?)
            usage
            exit 0
       ;;
       *)
            # Might be a USER name
            USER="$1"
            break;
       ;;
    esac

    shift # past argument
done

# Be sure NOT running as root
if [[ $EUID != 0 ]] ; then
    # NOT running as root
    USER=$(whoami)
else
    # Running as root,
    QUIET=1
    # find the correct /home/$USER/bin directory
    # Get list of users with home directories
    USERLIST="$(ls /home)"
    USERLIST="$(echo $USERLIST | tr '\n' ' ')"

    get_user
    # Verify user name passed on command line
    check_user
fi

LOCAL_BIN_PATH="/home/$USER/bin"

# If no port config file found create one
if [ ! -f $PORT_CFG_FILE ] ; then
    echo "No port config file: $PORT_CFG_FILE found, copying from repo." | $TEE_CMD
    sudo cp /home/$USER/n7nix/ax25/port.conf $PORT_CFG_FILE
fi

if [ $set_baudrate_flag = true ] ; then
    baudrate_config
else
    baudrate_toggle
fi

if [ 1 -eq 0 ] ; then
# Not sure if I need to do this.
# Makes script dependent on a particular radio
quietecho
quietecho "=== set alsa config"
if [ -z "$DEBUG" ] ; then
    sudo $LOCAL_BIN_PATH/setalsa-tmv71a.sh > /dev/null 2>&1
else
    # Verbose output
    sudo $LOCAL_BIN_PATH/setalsa-tmv71a.sh
fi
fi

quietecho
quietecho "=== reset direwolf & ax25 parms"

parent_check
parent_retcode=$?
# Execute reset_stack in a sub shell as a forked process
(reset_stack $parent_retcode ) &

echo "$(date): $scriptname exit" | $TEE_CMD
exit 0
