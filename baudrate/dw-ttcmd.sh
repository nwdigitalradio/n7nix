#!/bin/bash
#
# dw-ttcmd.sh
# Direwolf ttcmd to switch baud rate
DEBUG=1
if [ -z $DEBUG ] ; then
    sudo echo "$(date) ttcmd test." >> /home/pi/tmp/dw-log.txt
fi

ttstring=$(grep -i aprstt /var/log/direwolf/direwolf.log | tail -1)
# means "remove from string everyting from the searchstring onwards".
echo "ttstring: $ttstring"
searchstring="\[CN"
echo "baud: ${ttstring#*$searchstring}"

baudrate=$(echo "${ttstring#*$searchstring}" | cut -f1 -d ']')
echo "baudrate: $baudrate"
#$ value=${str#*=}
#echo "1: ${ttstring%*$searchstring}"
#echo "2: ${ttstring%%*$searchstring}"
#echo "3: ${ttstring#*$searchstring}"
#echo "4: ${ttstring##*$searchstring}"
