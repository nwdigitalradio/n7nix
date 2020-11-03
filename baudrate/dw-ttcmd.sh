#!/bin/bash
#
# dw-ttcmd.sh
# Direwolf ttcmd to switch baud rate
DEBUG=
USER=$(whoami)
scriptname="`basename $0`"

DW_TT_LOG_FILE="/home/$USER/tmp/dw-log.txt"
DW_LOG_FILE="/var/log/direwolf/direwolf.log"
PORT_CFG_FILE="/etc/ax25/port.conf"

# ===== function debugecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function verify_baud
# Verify current baud rate
function verify_baud() {
modem_cnt=$(sed -n "0,/^MODEM/! {/^MODEM/p}" /etc/direwolf.conf | wc -l)
if (( $modem_cnt > 2 )) || (( $modem_cnt == 0 )) ; then
    echo "ERROR: MODEM entry count: $modem_cnt"
    echo "Check /etc/direwolf.conf file."
    exit 1
fi
    # get baud rate from direwolf config file
    dw_baudrate0=$(sed -n "0,/^MODEM/! {/^MODEM/p}" /etc/direwolf.conf | head -n 1 | cut -d' ' -f2)
    dw_baudrate1=$(sed -n "0,/^MODEM/! {/^MODEM/p}" /etc/direwolf.conf | tail -n 1 | cut -d' ' -f2)

    # Get baud rate from port config file
    portcfg=port0
    pc_baudrate0=$(sed -n "/\[$portcfg\]/,/\[/p" $PORT_CFG_FILE | grep -i "^speed" | cut -f2 -d'=')
    portcfg=port1
    pc_baudrate1=$(sed -n "/\[$portcfg\]/,/\[/p" $PORT_CFG_FILE | grep -i "^speed" | cut -f2 -d'=')

    dbgecho "DEBUG: dw: 0 $dw_baudrate0, 1 $dw_baudrate0, port cfg: 0 $pc_baudrate0 1 $pc_baudrate1"

    if (( $dw_baudrate0 != $pc_baudrate0 )) ; then
        echo "ERROR: baud rates do not match: direwolf: $dw_baudrate0, port: $pc_baudrate0"
        exit 1
    else
        echo "Direwolf & port config OK"
    fi
}

# ===== function usage
function usage() {
   echo "Usage: $scriptname [-d][-h]" >&2
   echo "   -d                      set debug flag"
   echo "   -h                      no arg, display this message"
   echo
}

# ===== main

# Check if running as root
if [[ $EUID != 0 ]] ; then
   USER=$(whoami)
   dbgecho "Running as user: $USER"
else
    echo
    echo "Not required to be root to run this script."
    exit 1
fi

while [[ $# -gt 0 ]] ; do
key="$1"

case $key in
   -d|--debug)
      DEBUG=1
      echo "Debug mode on"
   ;;
   -h|--help|?)
      usage
      exit 0
   ;;
   *)
      # unknown option
      echo "Unknow option: $key"
      usage
      exit 1
   ;;
esac
shift # past argument or value
done

# First entry to log file
echo -n "$(date) ttcmd: " | tee -a $DW_TT_LOG_FILE

# Verify operating baudrate
verify_baud


FILESIZE=$(stat -c %s $DW_LOG_FILE)
if [ $FILESIZE -eq 0 ] ; then
    echo "Direwolf log file: $DW_LOG_FILE empty"
    DW_LOG_FILE="${DW_LOG_FILE}.1"
    FILESIZE=$(stat -c %s $DW_LOG_FILE)
    if [ $FILESIZE -eq 0 ] ; then
        echo "Direwolf log file: $DW_LOG_FILE empty"
        exit 1
    fi
fi

# Get call sign & baudrate from direwolf log file

### Method 1: use raw touch tone data

ttstring=$(grep -A 1 -i "Raw Touch Tone Data" $DW_LOG_FILE)
retcode="$?"
dbgecho "DEBUG: Search for 'Raw Touch Tone Data': ret: $retcode"
if [ "$retcode" -ne 0 ] ; then
    echo "No Touch Tone entries found in direwolf log file."
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
    echo "No Touch Tone entries found in direwolf log file."
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
    echo "Error: baudrates do not match: Method 1: $ttbrate, Method 2: $buadrate"
fi

# Check speed control file
# baud rate for left connector
curr_speed=$(grep -i "^speed=" /usr/local/etc/ax25/port.conf | head -n 1)
# Get string after match string (equal sign)
curr_speed="${curr_speed#*=}"

if [ "$curr_speed" = "${ttbrate}00" ] ; then
    # last entry to log file
    echo "No config necessary: baudrate: ${ttbrate}00, call sign: $ttcallsign" | tee -a $DW_TT_LOG_FILE
else
    # last entry to log file
    echo "Will config: baudrate: ${ttbrate}00, call sign: $ttcallsign" | tee -a $DW_TT_LOG_FILE
fi
