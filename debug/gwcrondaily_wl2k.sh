#!/bin/bash
#
# File : gwcrondaily_wl2k.sh
#
# Example crontab entry
# Sends report message @ 1 AM
# 0  1  * * * /home/pi/bin/gwcrondaily_wl2k.sh

scriptname="`basename $0`"

# default telnet transport
wl2ktransport="/usr/local/bin/wl2ktelnet -s"

# Example RMS Gateway transport
#  Need to edit <RMSGW> to be an RMS Gateway callsign
# wl2ktransport="/usr/local/bin/wl2kax25 -s -c <RMSGW>-10"

callsignfile="/usr/local/etc/wl2k.conf"
CALLSIGN=$(grep -i "mycall=" $callsignfile | grep -v "#" | awk -F = '{print $2} ')
SENDTO="$CALLSIGN@winlink.org"

station=$(uname -n)

WAIT_TIME=15
outboxdir="/usr/local/var/wl2k/outbox"

TMPDIR="$HOME/tmp"
outfile="$TMPDIR/dailycron.txt"
bindir="$HOME/bin"

#
# === function outbox_check() =================
# generate a mail msg & check for it in outbox
#
outbox_check() {

filecount_diff=0
filecountb4=$(ls -1 $outboxdir | wc -l)

if [ -z $filecountb4 ] ; then
  filecountb4=0
fi

mutt  -s "$subject" -c $SENDTO  < $outfile

# Postfix may take a while to deposit msg in outbox

filecountaf=$(ls -1 $outboxdir | wc -l)
# test if string has zero length ie. NULL
if [ -z $filecountaf ] ; then
  filecountaf=0
fi

time_start=$(date +"%s")

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
# Check if the email did not make it to the outbox
if ((filecount_diff == 0)) ; then
  echo "no change in filecount"
fi

return $filecount_diff
}

# ===== Main

# Check if tmp directory exists.
if [ ! -d "$TMPDIR" ] ; then
   mkdir -p $TMPDIR
fi

# === Generate body of email
$bindir/gwcron.sh > $outfile

# get the connection quality
## check for 0 logins
### strip leading white space

logins=$(cat $outfile | tr -d '\000' | grep login)
numlogins="$(echo $logins | awk '{print $1}')"
now=$(date --date="yesterday" "+%b %d %Y")

if (( numlogins > 0 )) ; then
	percentlogins="$(grep connection $outfile | awk '{print $1}')"
	echo "Positive number of logins $numlogins, percent: $percentlogins"
	subject=$(echo "//wl2k ##* $numlogins logins $percentlogins on $station for $now")
else
	echo "NO logins for this session"
	subject=$(echo "//wl2k ##* no logins on $station for $now")
fi

# === Generate a Winlink mail message & send via a Winlink transport

outbox_check
if [ "$?" -gt 0 ] ; then
    $wl2ktransport
    retcode=$?
    if [ $retcode -ne 0 ]; then
        echo "$scriptname: $(date): $(basename $wl2ktransport)  returned $retcode" >> $TMPDIR/dailyerror.txt
        exit 1
    fi
else
   echo "$scriptname: $(date): No mail found in winlink outbox"
fi

exit 0
