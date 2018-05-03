#!/bin/bash
#
# File: outboxchk.sh
#
# Check if there are any pending out going wl2k messages.
# Check last line of wl2ktelnet out for "refused".
#

user=$(whoami)
outboxdir="/usr/local/var/wl2k/outbox"
testfilename="/home/$user/tmp/wl2ktest.txt"
WL2KTEL="/usr/local/bin/wl2ktelnet"


# ===== function wl2ksend()
# Send messages in Winlink outbox via telnet

function wl2ksend () {

   $WL2KTEL -s &>> $testfilename

  lastline=$(tail -1 $testfilename)

   echo "Outbox sending $filecountb4 msgs"
   echo "Last line: $lastline"
}

# ===== Main

# check that WL2K program is installed in the path
type -P "$WL2KTEL" >/dev/null 2>&1
if [ $?  -ne 0 ]; then
   echo "Could not locate program: $WL2KTEL"
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
if [ -e $testfilename ] ; then
    rm $testfilename
fi

# Send messages found in outbox
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
  mv $testfilename $testfilename.$(date "+%d%H")
fi

exit 0
