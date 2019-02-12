#!/bin/bash
# tup.sh
#
# Test ax25-stop, ax25-start scripts

scriptname="`basename $0`"

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root"
   exit 1
fi

echo "$scriptname start"

{
/home/pi/bin/sysver.sh
echo
echo "ax25-stop at $(date)"

/home/pi/bin/ax25-stop

echo
echo "ax25-start at $(date)"

/home/pi/bin/ax25-start
journalctl --no-pager -u ax25dev.service
} > tupax25.log
echo "$scriptname finished"
exit 0
