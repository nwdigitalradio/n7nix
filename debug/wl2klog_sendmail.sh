#!/bin/bash
#
# File : dailytest.sh
#
# crontab should look something like this:
#
# 10 *  * * * /home/pi/bin/outboxchk.sh
# 59 23 * * * /home/pi/bin/daily_sendmail.sh
#

SENDTO="N0ONE"
wl2ktransport="/usr/local/bin/wl2ktelnet -s"
scriptname="`basename $0`"
user=$(whoami)

infologfile="/tmp/dailylog.txt"
errorlogfile="/home/$user/tmp/wl2ksendlog_error.txt"
tmplogfile="/home/$user/tmp/wl2ksendlog_tmp.txt"
outboxdir="/usr/local/var/wl2k/outbox"
WAIT_TIME=12

subject="//wl2k system check for $(hostname) on $(date "+%b %d %Y")"

# ===== function callsign_check()
# Check if there is a vaild SENDTO address
#  Default to CALLSIGN in direwolf config

callsign_check() {

if [ "$SENDTO" != "N0ONE" ] ; then
   # Script has been modified, just continue
   return
fi

if [ ! -e /etc/direwolf.conf ] ; then
   echo "$scriptname : NO Direwolf config file found!!"
   if [ "$SENDTO" = "N0ONE" ] ; then
      echo "$scriptname: need to edit this script with SENDTO address"
      exit 1
   fi
else
   CALLSIGN=$(grep -m 1 "^MYCALL" /etc/direwolf.conf | cut -d' ' -f2)
   SENDTO=$(echo $CALLSIGN | cut -d'-' -f1)
   echo "$scriptname: Callsign: $SENDTO used from Direwolf config file"
fi

if [ "$SENDTO" = "N0ONE" ] ; then
   echo "$scriptname: need to edit this script with SENDTO address"
   exit 1
fi
}

# ===== function outbox_check()
# Send msg & check for it in outbox

outbox_check() {

filecount_diff=0
filecountb4=$(ls -1 $outboxdir | wc -l)

if [ -z $filecountb4 ] ; then
  filecountb4=0
fi

mutt  -s "$subject" $SENDTO  < $infologfile

# Postfix takes a while to deposit mail in outbox

filecountaf=$(ls -1 $outboxdir | wc -l)

if [ -z $filecountaf ] ; then
  filecountaf=0
fi

# Initialize current time
time_start=$(date +"%s")

# Loop until new file appears in outbox or it times out
while :
do
   filecountaf=$(ls -1 $outboxdir | wc -l)

   if [ -z $filecountaf ] ; then
      filecountaf=0
   fi

   if [ "$filecountaf" -gt "$filecountb4" ] ; then
      break;
   fi

   time_current=$(date +"%s")
   timediff=$(($time_current - $time_start))
   if [ "$timediff" -gt "$WAIT_TIME" ] ; then
      break;
   fi
done

echo "file count b4: $filecountb4  after: $filecountaf in $timediff seconds"

filecount_diff=$((filecountaf - filecountb4))
if ((filecount_diff == 0)) ; then
   echo "Error: no change in filecount"
fi

return $filecount_diff
}

# ===== Main

# Verify a call sign for SENDTO
callsign_check

# generate some system info
source wl2klog_genmail.sh

echo "finished wl2klog_genmail.sh"

# Check if any mail is in outbox
outbox_check
if [ "$?" -gt 0 ] ; then

   # Find files that were created less than 10 minutes ago
   # xarg -0, input items terminate with null instead of white space
   dupecheck=$(find $outboxdir -type f -mmin -10 -print0 | xargs -0 ls -1 | wc -l)

   if ((dupecheck > 1)) ; then
      echo "Multiple msgs found: $outbox_newfile, dupecheck: $dupecheck"
      ls -salt $outboxdir
   fi

   echo "Sending $dupecheck new message(s)"

   $wl2ktransport >> $tmplogfile 2>&1
   retcode=$?

   if [ "$retcode" -ne 0 ]; then
      echo "$scriptname: $(date): $(basename $wl2ktransport) returned $retcode" >> $errorlogfile
      tail -n 2  $tmplogfile >> $errorlogfile
      exit 1
   fi
else
   echo "$scriptname: $(date): No mail found in outbox" >> $errorlogfile
fi

exit 0
