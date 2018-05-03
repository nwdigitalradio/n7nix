#!/bin/bash
#
# File : gwcrondaily_wl2k.sh
#
# Example crontab sends

# 0  1  * * * /home/gunn/bin/gwcrondaily_wl2k.sh

CALLSIGN="n7nix"
station=$(uname -n)
user=$(whoami)

WAIT_TIME=15
outboxdir="/usr/local/var/wl2k/outbox"

SENDTO="$CALLSIGN@winlink.org"
tmpdir="/home/${user}/tmp"
outfile="${tmpdir}/dailycron.txt"
bindir="/home/${user}/bin"

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
if [ ! -d "$tmpdir" ] ; then
   mkdir $tmpdir
fi

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

# === Generate a Winlink mail message

outbox_check

exit 0
