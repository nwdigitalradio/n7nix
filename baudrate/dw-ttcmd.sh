#!/bin/bash
#
# dw-ttcmd.sh
# Direwolf ttcmd to switch baud rate
#
# This script is called from direwolf running as root
#
DEBUG=

scriptname="`basename $0`"

PORT_CFG_FILE="/etc/ax25/port.conf"
DW_TT_LOG_FILE="/var/log/direwolf/dw-log.txt"
DW_LOG_FILE="/var/log/direwolf/direwolf.log"

# For display to console
#TEE_CMD="sudo tee -a $DW_TT_LOG_FILE"

# For logging to log file only!
# If you do not suppress stdout, direwolf will output it to radio in
# Morse Code.
TEE_CMD="sudo dd status=none of=$DW_TT_LOG_FILE oflag=append conv=notrunc"


# ===== function debugecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*" | $TEE_CMD; fi }

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

        REQUIRED_PROGRAM="speed_switch.sh"

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
# verify user name is legit

function check_user() {
   userok=false
   dbgecho "$scriptname: Verify user name: $USER"
   for username in $USERLIST ; do
      if [ "$USER" = "$username" ] ; then
         userok=true;
      fi
   done

   if [ "$userok" = "false" ] ; then
      echo "$scriptname: User name ($USER) does not exist,  must be one of: $USERLIST"
      exit 1
   fi

   dbgecho "using USER: $USER"
}

# ===== function verify_baud
# Verify current baud rate
function verify_baud() {
modem_cnt=$(sed -n "0,/^MODEM/! {/^MODEM/p}" /etc/direwolf.conf | wc -l)
if (( $modem_cnt > 2 )) || (( $modem_cnt == 0 )) ; then
    echo "ERROR: MODEM entry count: $modem_cnt" | $TEE_CMD
    echo "Check /etc/direwolf.conf file." | $TEE_CMD
    exit 1
fi
    # get baud rate from direwolf config file
    dw_baudrate0=$(sed -n "0,/^MODEM/ {/^MODEM/p}" /etc/direwolf.conf | head -n 1 | cut -d' ' -f2)
    dw_baudrate1=$(sed -n "0,/^MODEM/! {/^MODEM/p}" /etc/direwolf.conf | tail -n 1 | cut -d' ' -f2)

    # Get baud rate from port config file
    portcfg=port0
    pc_baudrate0=$(sed -n "/\[$portcfg\]/,/\[/p" $PORT_CFG_FILE | grep -i "^speed" | cut -f2 -d'=')
    portcfg=port1
    pc_baudrate1=$(sed -n "/\[$portcfg\]/,/\[/p" $PORT_CFG_FILE | grep -i "^speed" | cut -f2 -d'=')

    dbgecho "DEBUG: dw: 0 $dw_baudrate0, 1 $dw_baudrate0, port cfg: 0 $pc_baudrate0 1 $pc_baudrate1"

    if (( $dw_baudrate0 != $pc_baudrate0 )) ; then
        echo "$(date): ERROR: baud rates do not match: direwolf: $dw_baudrate0, port: $pc_baudrate0" | $TEE_CMD
        exit 1
    else
        dbgecho "Direwolf & port config OK"
    fi
}

# ===== function check_speed_config
# arg1 - requested baud rate
# Check modem baud rate amoung:
#   port.conf,
#   direwold config file
#   Touch Tone requested speed

function check_speed_config() {

    req_brate="$1"

    # Initialize baudrate boolean to false
    change_brate=0

    # from port config file: baud rate for left connector
    port_speed=$(grep -i "^speed=" $PORT_CFG_FILE | head -n 1)
    # Get string after match string (equal sign)
    port_speed="${port_speed#*=}"

    # from direwolf config file: baud rate for channel 0
    # first occurrence of MODEM keyword
    dw_speed0=$(grep  "^MODEM" /etc/direwolf.conf | sed -n '1 s/.* //p')

    # Reference
    # baud rate for channel 1 in direwolf config file
    # second occurrence
    #dw_speed1=$(grep  "^MODEM" /etc/direwolf.conf | sed -n '2 s/.* //p')

    # Check baud rate against port.conf file
    if [ "$port_speed" = "${req_brate}" ] ; then
        # last entry to log file
        dbgecho "port.conf: No config necessary: baudrate: ${req_brate}"
    else
        # log file entry
        dbgecho "port.conf: Requested baudrate change: baudrate: ${req_brate}"
        change_brate=1
    fi

    # Check baud rate against direwolf config file
    if [ "$dw_speed0" = "${req_brate}" ] ; then
        # log file entry
        dbgecho "direwolf.conf: No config necessary: baudrate: ${req_brate}"
        # Verify with port file
        if [ $change_brate -eq 1 ] ; then
            echo "ERROR: Mismatch in baud rates between port.conf ($port_speed) & direwolf.conf ($dw_speed0)" | $TEE_CMD
        fi
    else
        # log file entry
        dbgecho "direwolf.conf: Requested baudrate change: baudrate: ${req_brate}" | tee -a $DW_TT_LOG_FILE
        # Verify with port file
        if [ $change_brate -eq 0 ] ; then
            echo "ERROR: Mismatch in baud rates between port.conf ($port_speed) & direwolf.conf ($dw_speed0)" | $TEE_CMD
        fi

        change_brate=1
    fi
    return $change_brate
}

# ===== check_console
# Check if this script is running from a console
function check_console() {

    if [ -z "$PS1" ] ; then
        set_ps1flag=0
    else
        set_ps1flag=1
    fi

    # Cron does not by default allocate a tty to a script
    if [ -t 0 ] ; then
        set_ttyflag=1
    else
        set_ttyflag=0
    fi

    #PID test
    set_dwflag=0
    # Get parent pid of parent
    PPPID=$(ps h -o ppid= $PPID)
    # get name of the command
    P_COMMAND=$(ps h -o %c $PPPID)

    echo "P_COMMAND: $P_COMMAND" | $TEE_CMD
    # Test name against cron
    if [ "$P_COMMAND" == "direwolf" ]; then
        set_dwflag=1
    fi

    echo "$scriptname Start: $(date "+%Y %m %d %T %Z"): Options: $(echo $-), ps1: $set_ps1flag, tty: $set_ttyflag, dw: $set_dwflag" | $TEE_CMD
}

# ===== function usage
function usage() {
   echo "Usage: $scriptname [-d][-h]" >&2
   echo "   -d         set debug flag"
   echo "   -h         no arg, display this message"
   echo
}

# ===== main

# Check if running as root
if [[ $EUID != 0 ]] ; then
    # NOT running as root
    USER=$(whoami)
    echo "$scriptname: Running as user: $USER" | $TEE_CMD
else
    # Running as root, find the correct /home/$USER/bin directory
    # Get list of users with home directories
    USERLIST="$(ls /home)"
    USERLIST="$(echo $USERLIST | tr '\n' ' ')"

    get_user
    check_user
fi

LOCAL_BIN_PATH="/home/$USER/bin"

while [[ $# -gt 0 ]] ; do
key="$1"

case $key in
   -d|--debug)
      DEBUG=1
      echo "Debug mode on" | $TEE_CMD
   ;;
   -h|--help|?)
      usage
      exit 0
   ;;
   *)
      # unknown option
      echo "Unknow option: $key"  | $TEE_CMD
      usage
      exit 1
   ;;
esac
shift # past argument or value
done

# Verify operating baudrate
verify_baud


FILESIZE=$(stat -c %s $DW_LOG_FILE)
if [ $FILESIZE -eq 0 ] ; then
    echo "Direwolf log file: $DW_LOG_FILE empty"  | $TEE_CMD
    DW_LOG_FILE="${DW_LOG_FILE}.1"
    FILESIZE=$(stat -c %s $DW_LOG_FILE)
    if [ $FILESIZE -eq 0 ] ; then
        echo "$(date): Direwolf log file: $DW_LOG_FILE empty"  | $TEE_CMD
        exit 1
    fi
fi

# Verify baud rate in object sent via touch tones

### Method 1: use raw touch tone data

ttstring=$(grep -A 1 -i "Raw Touch Tone Data" $DW_LOG_FILE)
retcode="$?"
dbgecho "DEBUG: Search for 'Raw Touch Tone Data': ret: $retcode"
if [ "$retcode" -ne 0 ] ; then
    echo "$(date): No Raw Touch Tone entries found in direwolf log file." | $TEE_CMD
    exit 1
fi
lines=$(wc -l <<< $ttstring)
ttstring=$(echo "$ttstring" | tail -n 1 | cut -f4 -d ':')

# echo "DEBUG: ttstring: ($lines): $ttstring"

# parse out baud rate
# sed note: "remove from string everyting from the searchstring onwards".
ttbrate=$(sed -n 's/BA//p' <<< "$ttstring" | cut -d'*' -f1)
ttbrate=$(tt2text $ttbrate | tail -n 1)
# Remove surrounding double quotes
ttbrate=${ttbrate%\"}
ttbrate=${ttbrate#\"}
ttbrate=$(echo $ttbrate | cut -c3-4)

# parse out call sign

ttcallsign=$(sed -n 's/BA//p' <<< "$ttstring" | cut -d'*' -f2 | cut -d'#' -f1)
# Remove First (A) & last (checksum) character in string
ttcallsign="${ttcallsign#?}"
ttcallsign="${ttcallsign%?}"
ttcallsign=$(tt2text $ttcallsign | tail -n 1)
# Remove surrounding double quotes
ttcallsign=${ttcallsign%\"}
ttcallsign=${ttcallsign#\"}

dbgecho "Method 1: baudrate: $ttbrate, call sign: $ttcallsign"

### Method 2: use generated APRS object [APRStt]

ttstring=$(grep -i "aprstt" $DW_LOG_FILE)
retcode="$?"
dbgecho "DEBUG: Search for aprstt: ret: $retcode"
if [ "$retcode" -ne 0 ] ; then
    echo "$(date): No APRStt Touch Tone entries found in direwolf log file." | $TEE_CMD
    exit 1
fi
lines=$(wc -l <<< $ttstring)
ttstring=$(echo "$ttstring" |tail -1)
# means "remove from string everyting from the searchstring onwards".
# echo "DEBUG: ttstring: ($lines): $ttstring"
searchstring="\[CN"
#echo "baud: ${ttstring#*$searchstring}"

# Get string after match string
baudrate=$(echo "${ttstring#*$searchstring}" | cut -f1 -d ']')
if [ "$baudrate" = "$ttbrate" ] ; then
    dbgecho "APRS object & raw tt data Baud rates confirm"
else
    echo "Error: baud rates do not match: Method 1: $ttbrate, Method 2: $baudrate" | $TEE_CMD
fi

# check_console

# Check if current speed config needs to change
check_speed_config "${ttbrate}00"
if [ $? -eq 1 ] ; then
    echo "$(date): ttcmd requested baudrate: ${baudrate}00 change" | $TEE_CMD
    $LOCAL_BIN_PATH/speed_switch.sh -b ${baudrate}00 $USER
else
    echo "$(date): ttcmd requested baudrate: ${dw_speed0}, NO change" | $TEE_CMD
fi

echo "$(date): $scriptname exit" | $TEE_CMD
exit 0
