#!/bin/bash
#
# Uncomment this statement for debug echos
DEBUG=1

USER=pi
scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

#
# Required programs
# Note telnet is used to test a dovecot mail server
MAIL_PKG_REQUIRELIST="postfix dovecot-core dovecot-imapd telnet"
EXITFLAG=false

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# ===== main

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root."
   exit 1
fi

if [ ! -f /etc/mailname ] ; then
   echo "$(hostname).localdomain" > /etc/mailname
fi

# check if packages are installed
dbgecho "Check packages: $MAIL_PKG_REQUIRELIST"
needs_pkg=false

for pkg_name in `echo ${MAIL_PKG_REQUIRELIST}` ; do

   is_pkg_installed $pkg_name
   if [ $? -ne 0 ] ; then
      echo "$scriptname: Will Install $pkg_name program"
      needs_pkg=true
      break
   fi
done

if [ "$needs_pkg" = "true" ] ; then
   debconf-set-selections <<< "postfix postfix/mailname string $(hostname).localhost"
   debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
   apt-get install -y -q $MAIL_PKG_REQUIRELIST
else
   echo
   echo "No Mail Package installation required, Is this a subsequent install?"
   echo
fi

echo "$(date "+%Y %m %d %T %Z"): imapserv install script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "imapserv install FINISHED"
echo
