#!/bin/bash
#

#
# Required programs
PROGLIST="postfix dovecot"
myname="`basename $0`"
EXITFLAG=false

for prog_name in `echo ${PROGLIST}` ; do

   type -P $prog_name &>/dev/null
   if [ $? -ne 0 ] ; then
      echo "$myname: Need to Install $prog_name program"
      EXITFLAG=true
   fi
done
if [ "$EXITFLAG" = "true" ] ; then
   debconf-set-selections <<< "postfix postfix/mailname string your.hostname.com"
   debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
   apt-get install -y postfix
fi

if [ ! -f /etc/mailname ] ; then
   echo "$(hostname).localhost" > /etc/mailname
fi
exit 0