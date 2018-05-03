#!/bin/sh
#
# File : gwcron.sh
#
# $Id: gwcron.sh 76 2013-12-01 22:33:42Z gunn $
# $LastChangedDate: 2013-12-01 14:33:42 -0800 (Sun, 01 Dec 2013) $
#

# Name of this script
myname="`basename $0`"

LOGFILE="/var/log/rms.debug"
TMPLOGFILE="/tmp/rms.tmp"
callsignfile="/usr/local/etc/wl2k.conf"
CALLSIGN=$(grep -i "mycall=" $callsignfile | grep -v "#" | awk -F = '{print $2} ')

LOGINCNT=""
LOGOUTCNT=""

# Get search date for log file
XDATE=`date --date="yesterday" "+%b %_d"`

echo "### $(date) Test Message from $CALLSIGN-10"

# Since using logrotate aggregate all the entries for DATE
if [ -f $LOGFILE.1 ] ; then
  echo "$myname: Found rotated log file!"
# remove all non-printable ascii chars
# tr -cd '\11\12\40-\176'
  grep -i "${XDATE}" $LOGFILE.1 | tr -cd '\11\12\40-\176' > $TMPLOGFILE
fi

# remove all non-printable ascii chars
# tr -cd '\11\12\40-\176'
grep -i "${XDATE}" $LOGFILE | tr -cd '\11\12\40-\176' >> $TMPLOGFILE

#LOGINCNT=$(grep -i "${XDATE}" $LOGFILE | grep -i login | wc -l)
LGINCNT=$(grep -i "${XDATE}" $TMPLOGFILE | grep -ic Login)
LGOUTCNT=$(grep -i "${XDATE}" $TMPLOGFILE | grep -ic Logout)

# Capture the logout error count which will happen when the internet is
#  down or all the CMS are down.
LGOUTERRCNT=$(grep -i "${XDATE}" $TMPLOGFILE | grep -ic "logout ERROR:")

# Are there any logout errors?
if [ $LGOUTERRCNT -ne 0 ] && [ $LGOUTCNT -gt $LGOUTERRCNT ]; then
  echo "NOTE: Logout: $LGOUTCNT, Logout error: $LGOUTERRCNT"
  LGOUTCNT=`expr $LGOUTCNT - $LGOUTERRCNT`
fi

echo
echo "$LGINCNT logins and $LGOUTCNT logouts on ${XDATE}"
if [ $LGINCNT -gt 0 ]; then
   echo "`expr $LGOUTCNT  \* 100 / $LGINCNT`% connection success."
   echo
   echo "List of Stations that logged in:"
   grep -i "$XDATE" $TMPLOGFILE | grep "Login" | cut -d':' -f4 | cut -d' ' -f3 | sort | uniq
fi

echo
echo Uptime: $(uptime)
echo
echo $(df -h | grep -i root)
echo

# Changed for Debian stretch due to ifconfig output changed.
# echo "local ip addr: $(/sbin/ifconfig eth0 | grep "inet addr" | awk '{ print $2} ' |cut -d: -f 2)"
echo "local ip addr: $(/sbin/ifconfig eth0 | grep "inet " | grep -Po '(\d+\.){3}\d+' | head -1)"

exit 0
