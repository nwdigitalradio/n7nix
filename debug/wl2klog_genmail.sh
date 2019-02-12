#!/bin/bash
#
# File: daily_genmail.sh
#
# Generate a report on system

scriptname="`basename $0`"
HOSTNAME="$(hostname)"
user=$(whoami)
reportname="$HOSTNAME Report"

#send report to:
MAILTO="gunn@$HOSTNAME"
# Mail user agent
MUA="/usr/bin/mutt"
logfile="/tmp/dailylog.txt"

# ===== Main

{
   echo "$reportname on `date`"
   echo
   echo "Uptime: $(uptime)"
   echo
   # Report some disk usage
   echo "---- Disk Usage:"
   echo
   /bin/df -h
   echo
   echo "---- Logged-in Info:"
   echo
   # who is logged in
   /usr/bin/w
   echo
   echo "---- Users running processes:"
   echo
   # Show which users are running processes
   ps aux | awk '{ print $1 }' | sed '1 d' | sort | uniq
   echo
   echo "---- AX.25 device service"
   echo
   systemctl --no-pager status ax25dev.service
   echo
   echo "---- direwolf service"
   echo
   systemctl --no-pager status direwolf.service
   echo

   echo "$scriptname finished"
} > $logfile

echo "$scriptname finished"
