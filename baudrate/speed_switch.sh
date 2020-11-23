#!/bin/sh
# version: 1.1
#
# Switch for 1200 baud and 9600 baud packet speed
# When called
# Script syntax changed from bash to Bourne shell to run from 'at' command
#
DEBUG=
QUIET=
USER=
set_baudrate_flag=false

scriptname="`basename $0`"

# Default audio device name
AUDIO_DEV="udrc"

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
dbgecho() { if [ ! -z "$DEBUG" ] ; then echo "$*" | $TEE_CMD; fi }

# if QUIET is defined then DO NOT echo
quietecho() { if [ -z "$QUIET" ] ; then echo "$*"; fi }

# ===== function get_user
# When running as root need to find a valid local bin directory
# Set USER based on finding a REQUIRED_PROGRAM

get_user() {
    # Check if there is only a single user on this system
    if [ $(ls /home | wc -l) -eq 1 ] ; then
        USER=$(ls /home)
    else
        USER=
        # Get here when there is more than one user on this system,
        # Find the local bin that has the requested program

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

check_user() {
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

get_port_speed() {
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

# ===== function display_ctrl
# NWDR Draws audio card specific

display_ctrl() {

    alsa_ctrl="$1"
    CTRL_STR="$(amixer -c $AUDIO_DEV get \""$alsa_ctrl"\")"
#    dbgecho "$alsa_ctrl: $CTRL_STR"
    CTRL_VAL=$(amixer -c $AUDIO_DEV get \""$alsa_ctrl"\" | grep -i -m 1 "Item0:" | cut -d ':' -f2)
    # Remove preceeding white space
#   BASH CTRL_VAL="$(sed -e 's/^[[:space:]]*//' <<<"$CTRL_VAL")"
    # Bourne
    CTRL_VAL="$(echo "$CTRL_VAL" | sed -e 's/^[[:space:]]*//')"

    # Remove surrounding quotes
    CTRL_VAL=${CTRL_VAL%\'}
    CTRL_VAL=${CTRL_VAL#\'}
}

# ===== function check_alsa_settings
# NWDR Draws audio card specific

check_alsa_settings() {
    echo " === ALSA 1200/9600 route settings"
    control="IN1_L to Left Mixer Positive Resistor"
    display_ctrl "$control"
    CTRL_IN1_L="$CTRL_VAL"

    control="IN1_R to Right Mixer Positive Resistor"
    display_ctrl "$control"
    CTRL_IN1_R="$CTRL_VAL"

    control="IN2_L to Left Mixer Positive Resistor"
    display_ctrl "$control"
    CTRL_IN2_L="$CTRL_VAL"

    control="IN2_R to Right Mixer Positive Resistor"
    display_ctrl "$control"
    CTRL_IN2_R="$CTRL_VAL"

    control="IN1"
    strlen=${#CTRL_IN1_L}
#    expr strlen ${CTRL_IN1_L}
    if [ $strlen -lt 4 ] ; then
        printf "%s\t\tL:[%s]\t\tR:[%s]\n" "$control" "$CTRL_IN1_L" "$CTRL_IN1_R"
    else
        printf "%s\t\tL:[%s]\tR:[%s]\n" "$control" "$CTRL_IN1_L" "$CTRL_IN1_R"
    fi

    control="IN2"
    strlen=${#CTRL_IN2_L}
    if [ $strlen -lt 4 ] ; then
        printf "%s\t\tL:[%s]\t\tR:[%s]\n" "$control" "$CTRL_IN2_L" "$CTRL_IN2_R"
    else
        printf "%s\t\tL:[%s]\tR:[%s]\n" "$control" "$CTRL_IN2_L" "$CTRL_IN2_R"
    fi
}

# ===== function speed_status

# Display parameters used for kissattach & AX.25 device

speed_status() {

    SLOTTIME=
    TXDELAY=
    T1_TIMEOUT=
    T2_TIMEOUT=
#    declare -A devicestat=([ax0]="exists" [ax1]="exists")
    devicestat0="exists"
    devicestat1="exists"

    # Check if direwolf is already running.
    pid=$(pidof direwolf)
    if [ $? -eq 0 ] ; then
        #dbgecho "$(date): ${FUNCNAME[0]}: Direwolf is running with pid of $pid" | $TEE_CMD
        dbgecho "$(date): speed_status: Direwolf is running with pid of $pid" | $TEE_CMD
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
#            devicestat[$devname]="does NOT exist"
             devicestat$devnum="does NOT exist"
        fi
        echo "port: $devnum, speed: $PORTSPEED, slottime: $SLOTTIME, txdelay: $TXDELAY, t1 timeout: $T1_TIMEOUT, t2 timeout: $T2_TIMEOUT"
    done
    # Use a single line for device status
#    echo "Device: ax0 ${devicestat[ax0]}, Device: ax1 ${devicestat[ax1]}"
    echo "Device: ax0 ${devicestat0}, Device: ax1 ${devicestat1}"
    # Display NWDR Draws card alsa 1200/9600 baud routing (IN1, IN2)
    check_alsa_settings
}

# ===== function dw_speed_cnt

dw_speed_cnt() {
    speed_cnt=$(grep "^MODEM" $DIREWOLF_CFGFILE | wc -l)
    if [ $speed_cnt -gt 0 ] && [ $speed_cnt -le 2 ] ; then
        dbgecho "There are $speed_cnt instances of MODEM speed."
    else
        echo "Error: Wrong count of MODEM speed instances: $speed_cnt" | $TEE_CMD
    fi
}

# ===== function direwolf_set_baud

# Set baud rate on MODEM line for the first modem channel

direwolf_set_baud() {

    modem_speed="$1"

    echo "$(date): speed_switch set $DIREWOLF_CFGFILE baud rate to: $modem_speed" | $TEE_CMD

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

set_baudrate() {
    portnum="$1"
    baudrate="$2"
    receive_out="$3"

    echo "$(date): speed_switch set $PORT_CFG_FILE baud rate to: $baudrate" | $TEE_CMD
    # Switch speeds in port config file
    sudo sed -i -e "/\[port$portnum\]/,/\[/ s/^speed=.*/speed=$baudrate/" $PORT_CFG_FILE
    # Set audio/disc in port config file
    sudo sed -i -e "/\[port$portnum\]/,/\[/ s/^receive_out=.*/receive_out=$receive_out/" $PORT_CFG_FILE

    direwolf_set_baud $baudrate
}
# function get_baudrates
get_baudrates() {
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

baudrate_toggle() {

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
baudrate_config() {
    # set variables ax25_udr0_baud, ax25_udr1_baud=0

    get_baudrates

    dbgecho " === set baudrate to: $baudrate"
    if [ "$baudrate" = "$ax25_udr0_baud" ] && [ $(pidof direwolf) ] ; then
        echo " === baud rate already set to $baudrate & direwolf is running" | $TEE_CMD
        return 0
    fi

    # default receive to discriminator
    # port number, speed (1200/9600) receive_out (audio/disc)
    set_baudrate 0 $baudrate "disc"
    return 1
}

# ===== function switch_config

# Switch a single port based upon config file setting.
# NOTE: only switches port 0

switch_config() {

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
# This script could be run from
#  - console
#  - direwolf
#  - atd
# If running from console or atd return 0, ax25 restart immediately
# If running from direwolf return 1
#    and wait some time for morse code 'R'

parent_check() {
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
        echo "$P_COMMAND" | grep -iq "atd"
        # return code will be:
        # 0 if running from atd
        # 1 if running from direwolf
        retcode=$?
    fi
    return $retcode
}

# ===== function reset_stack
reset_stack() {
    QUIET="-q"

    dbgecho "reset_stack arg: $1"  | $TEE_CMD
    # bash: startsec=$SECONDS
    startsec=$(($(date +%s%N)/1000000))

    # If running from direwolf then wait for the morse code response
    if [ "$1" -eq 1 ] ; then
        # Called from direwolf
        wait4morse=$(tail -n 5 $DW_LOG_FILE| grep -i "\[0.morse\]")
        grepret=$?
        while [ $grepret -ne 0 ] ; do
            wait4morse=$(tail -n 5 $DW_LOG_FILE| grep -i "\[0.morse\]")
            grepret=$?
        done

        currentsec=$(($(date +%s%N)/1000000))
        echo "Would do a direwolf reset now, after `expr $currentsec - $startsec` mSec" | $TEE_CMD
#       at now + 1 min -f /home/pi/bin/ax25-restart
        # Use time second resolution when run using 'at' command
        at -t $(date --date="now +5 seconds" +"%Y%m%d%H%M.%S") -f $LOCAL_BIN_PATH/ax25-restart  > /dev/null 2>&1
    else
        # Called from console
        $LOCAL_BIN_PATH//ax25-restart  > /dev/null 2>&1
    fi

    currentsec=$(($(date +%s%N)/1000000))
    echo "$(date): reset_stack exit, wait(`expr $currentsec - $startsec` mSec)" | $TEE_CMD
}

# ===== function usage

usage() {
   echo "Usage: $scriptname [-b <speed>][-s][-d][-h][USER]" >&2
   echo " Default to toggling baud rate when no command line arguments found."
   echo "   -b | --baudrate <baudrate>  Set baud rate speed, 1200 or 9600"
   echo "   -s | --status          Display current status of devices & ports"
   echo "   -d | --debug           Set debug flag for verbose output"
   echo "   -h | --help            Display this message"
   echo
}

# ===== main

# If running from 'at' command no command line arguments are allowed,
# but will want to reset baud rate config to 1200 baud
if [ $# -eq 0 ] ; then
    # Get parent pid of parent
    PPPID=$(ps h -o ppid= $PPID)
    # get name of the command
    P_COMMAND=$(ps h -o %c $PPPID)

    echo "$(date): speed_switch: running from: $P_COMMAND" | $TEE_CMD
    echo "$P_COMMAND" | grep -iq "atd"
    if [ "$?" -eq 0 ] ; then
        baudrate="1200"
        set_baudrate_flag=true
    fi
fi

while [ $# -gt 0 ] ; do
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
if [  $(id -u) != 0 ] ; then
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
    # Verify baudrate value & if running in a console rather than
    # 'at' or direwolf
    baudrate_config
    if [ $? -eq 0 ] && [ -t 0 ] ; then
        echo "Local baud rate already set to: $baudrate"
        exit 0
    fi
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
# arg = 0: running from console or atd
# arg = 1: running from direwolf
(reset_stack $parent_retcode ) &

echo "$(date): speed_switch ($scriptname) exit" | $TEE_CMD
exit 0
