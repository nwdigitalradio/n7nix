#!/bin/bash
#
# dw-ttcmd.sh
# Direwolf ttcmd to switch baud rate
DEBUG=
USER=pi

DW_TT_LOG_FILE="/home/$USER/tmp/dw-log.txt"
DW_LOG_FILE="/var/log/direwolf/direwolf.log"

# ===== function debugecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== main

# First entry to log file
echo -n "$(date) ttcmd: " | tee -a $DW_TT_LOG_FILE

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
    dbgecho "Baud rates confirm"
else
    echo "Error: baudrates do not match: Method 1: $ttbrate, Method 2: $buadrate"
fi

# last entry to log file
echo "baudrate: $ttbrate00, call sign: $ttcallsign" | tee -a $DW_TT_LOG_FILE

# Check speed control file
# baud rate for left connector
curr_speed=$(grep -i "^speed=" /usr/local/etc/ax25/port.conf | head -n 1)
# Get string after match string (equal sign)
curr_speed="${curr_speed#*=}"

if [ "$curr_speed" = "${ttbrate}00" ] ; then
    echo "speed already set to $curr_speed"
else
    echo "Configuring direwolf for new speed ${ttbrate}00"
fi
