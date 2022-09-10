#!/bin/bash
#
# File: wl2k_outboxchk.sh
#
# Check if there are any pending out going wl2k messages.
# Check last line of wl2k transport program for "refused".
# Get the wl2k transport program from wl2log_sendmail.sh script

scriptname="`basename $0`"
VERSION="1.2"

user=$(whoami)
outboxdir="/usr/local/var/wl2k/outbox"
error_logfile="/home/$user/tmp/wl2ksendchk_error.txt"
sys_logfile="/var/log/syslog"

# ===== function wl2ksend()
# Send messages in Winlink outbox via telnet

function wl2ksend () {

   echo "$scriptname: $(date): starting winlink cmd from $scriptname ver: $VERSION" | tee -a $error_logfile
   $WL2KXPORT -s >> $error_logfile 2>&1

   lastline=$(tail -1 $error_logfile)

   echo "Outbox sending $filecountb4 msgs"
   echo "Last line: $lastline"
}

# ===== function usage

function usage() {
   echo "Usage: $scriptname [-l][-h]" >&2
   echo "   -l                display log files"
   echo "   -h | --help       display this message"
   echo
   echo
}

# ===== Main

# if there are any args then parse them
while [[ $# -gt 0 ]] ; do
   key="$1"

   case $key in
      -l)   # display log files

          echo "Logile: $error_logfile"
	  echo "--------------------------------------------"
          cat $error_logfile

	  echo
	  echo "Logfile: $sys_logfile"
	  echo "------------------------"
          grep -i "wl2k_*" $sys_logfile

          exit 0
          ;;
      -h|--help)
          usage
	  exit 0
	  ;;
      *)
          echo "Unknown option: $key"
	  usage
	  exit 1
	  ;;
   esac
shift # past argument or value
done

WL2KXPORT=$(grep -m 1 "wl2ktransport" /home/$user/bin/wl2klog_sendmail.sh  | cut -d"=" -f2 | cut -d" " -f1)

# remove leading quote
WL2KXPORT=$(echo "${WL2KXPORT#\"}")

# check that script wl2klog_sendmail.sh exists
if [ ! -e "/home/$user/bin/wl2klog_sendmail.sh" ] ; then
    WL2KXPORT="/usr/local/bin/wl2ktelnet"
fi

# check that WL2K program is installed in the path
type -P "$WL2KXPORT" >/dev/null 2>&1
if [ $?  -ne 0 ]; then
    echo "Could not locate program: $WL2LXPORT" | tee -a $error_logfile
    exit 1
else
    WL2KXPORT="/usr/local/bin/wl2ktelnet"
fi

filecountb4=$(ls -1 $outboxdir | wc -l)

if [ -z $filecountb4 ] ; then
  filecountb4=0
fi

# If nothing in outbox just exit
if [ "$filecountb4" -eq 0 ]; then
#  echo "Outbox empty."
    echo "$scriptname ($VERSION): $(date): No file in outbox" | tee -a $error_logfile
    exit 0
fi

# If the output file exists delete it
if [ -e $error_logfile ] ; then
    rm $error_logfile
fi

# Send messages found in outbox
#  using wl2k transport defined in wl2klog_sendmail.sh
wl2ksend

# check if connection was refused
echo $lastline | grep -i "refused"  > /dev/null
if [ $? -eq 0 ] ; then
    echo "Connection refused, retrying" | tee -a $error_logfile

    wl2ksend

    echo $lastline | grep -i "refused"  > /dev/null
    if [ $? -eq 0 ] ; then
	echo "Connection refused TWICE, exiting!" | tee -a $error_logfile
    fi
    # Save the output file, might learn something
    mv $error_logfile $error_logfile.$(date "+%d%H")
fi

exit 0
