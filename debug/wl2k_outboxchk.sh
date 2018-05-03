#!/bin/bash
#
# File: wl2k_outboxchk.sh
#
# Check if there are any pending out going wl2k messages.
# Check last line of wl2k transport program for "refused".
# Get the wl2k transport program from wl2log_sendmail.sh script

scriptname="`basename $0`"
user=$(whoami)
outboxdir="/usr/local/var/wl2k/outbox"
errorlogfile="/home/$user/tmp/wl2ksendchk_error.txt"

WL2KXPORT=$(grep -m 1 "wl2ktransport" wl2klog_sendmail.sh  | cut -d"=" -f2 | cut -d" " -f1)

#remove leading quote
WL2KXPORT=$(echo "${WL2KXPORT#\"}")

# ===== function wl2ksend()
# Send messages in Winlink outbox via telnet

function wl2ksend () {

   echo "$scriptname: $(date): starting winlink cmd" >> $errorlogfile
   $WL2KXPORT -s >> $errorlogfile 2>&1

   lastline=$(tail -1 $errorlogfile)

   echo "Outbox sending $filecountb4 msgs"
   echo "Last line: $lastline"
}

# ===== Main

# check that WL2K program is installed in the path
type -P "$WL2KXPORT" >/dev/null 2>&1
if [ $?  -ne 0 ]; then
   echo "Could not locate program: $WL2LXPORT"
   exit 1
fi

filecountb4=$(ls -1 $outboxdir | wc -l)

if [ -z $filecountb4 ] ; then
  filecountb4=0
fi

# If nothing in outbox just exit
if [ "$filecountb4" -eq 0 ]; then
#  echo "Outbox empty."
  exit 0
fi

# If the output file exists delete it
if [ -e $errorlogfile ] ; then
    rm $errorlogfile
fi

# Send messages found in outbox
#  using wl2k transport defined in wl2klog_sendmail.sh
wl2ksend

# check if connection was refused
echo $lastline | grep -i "refused"  > /dev/null
if [ $? -eq 0 ] ; then
    echo "Connection refused, retrying"

    wl2ksend

    echo $lastline | grep -i "refused"  > /dev/null
    if [ $? -eq 0 ] ; then
	echo "Connection refused TWICE, exiting!"
    fi
    # Save the output file, might learn something
    mv $errorlogfile $errorlogfile.$(date "+%d%H")
fi

exit 0
