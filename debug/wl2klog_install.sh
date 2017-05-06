#!/bin/bash
#
# Install files required to enable a daily sys report in your mail box.
#  - Create a crontab if non exists
#  - Copy script files to a user's bin directory
#
USER=$(whoami)
scriptname="`basename $0`"

userbindir=/home/$USER/bin
usertmpdir=/home/$USER/tmp
REQUIRED_SCRIPTS="wl2k_outboxchk.sh wl2klog_genmail.sh wl2klog_install.sh wl2klog_sendmail.sh"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ==== Function checkDir
#  arg: directory to verify
#  -- creates directory $1, if it does not exist
checkDir() {
   if [ ! -d "$1" ] ; then
      mkdir -p "$1"
   fi
}

# ==== main

# Be sure we are NOT running as root
if (( `id -u` == 0 )); then
   echo "$scriptname: Sorry, must NOT be root.  Exiting...";
   echo "Login as user with Winlink email account."
   exit 1;
fi

# Check if local tmp directory exists
checkDir $usrbindir

# Check for previous install
for filename in `echo ${REQUIRED_SCRIPTS}` ; do

   # Check if file exists.
   if [ -f "$userbindir/$filename" ] ; then
      dbgecho "Comparing $filename"
      diff -s $filename $userbindir/$filename
      if [ $? -ne 0 ] ; then
         cp $filename $userbindir/$filename
      fi
   else
      echo "$scriptname: File: $userbindir/$filename DOES NOT EXIST"
      cp $filename $userbindir/$filename
   fi
done

# Does user have a crontab?
crontab -u $USER -l > /dev/null 2>&1
if [ $? -ne 0 ] ; then
   echo "user $USER does NOT have a crontab, creating"
   crontab  -l ;
   {
   echo "# m h  dom mon dow   command"
   echo "10 *  * * * $userbindir/wl2k_outboxchk.sh > /dev/null 2>&1"
   echo "59 23 * * * $userbindir/wl2klog_sendmail.sh > /dev/null 2>&1"
   } | crontab -
else
   echo "$scriptname: User: $USER already has a crontab"
fi

echo "$scriptname: User: $USER crontab looks like this:"
echo
crontab -l
echo
echo "$scriptname Testing install ... look for Winlink e-mail."
echo
$userbindir/wl2klog_sendmail.sh
echo
echo "$scriptname: Finished"
