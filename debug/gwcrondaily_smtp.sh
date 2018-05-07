#!/bin/bash
#
# File : gwcrondaily_smtp.sh
#
# Example crontab emails report at 1AM
#
# 0  1  * * * /home/gunn/bin/gwcrondaily_smtp.sh

station=$(uname -n)
user=$(whoami)

SENDTO="gunn@beeble.localnet"
tmpdir="/home/${user}/tmp"
outfile="${tmpdir}/dailycron.txt"
bindir="/home/${user}/bin"

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

mutt  -s "$subject" $SENDTO  < $outfile

exit 0
