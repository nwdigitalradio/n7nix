#!/bin/bash
#
# Uncomment this statement for debug echos
DEBUG=1
USER=pi
myname="`basename $0`"

#
# Required programs
MAIL_PKG_REQUIRELIST="postfix dovecot"
EXITFLAG=false

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }


if [ ! -f /etc/mailname ] ; then
   echo "$(hostname).localhost" > /etc/mailname
fi

for prog_name in `echo ${MAIL_PKG_REQUIRE}` ; do

   type -P $prog_name &>/dev/null
   if [ $? -ne 0 ] ; then
      echo "$myname: Need to Install $prog_name program"
      EXITFLAG=true
   fi
done

if [ "$EXITFLAG" = "true" ] ; then
   debconf-set-selections <<< "postfix postfix/mailname string $(hostname).localhost"
   debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
   apt-get install -y postfix dovecot
fi


# prompt for user name
# Check if there is only a single user on this system

USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

if (( `ls /home | wc -l` == 1 )) ; then
   USER=$(ls /home)
else
  echo "Enter user name ($(echo $USERLIST | tr '\n' ' ')), followed by [enter]:"
  read USER
fi

# verify user name is legit
userok=false

for username in $USERLIST ; do
  if [ "$USER" = "$username" ] ; then
     userok=true;
  fi
done

if [ "$userok" = "false" ] ; then
   echo "User name does not exist,  must be one of: $USERLIST"
   exit 1
fi

dbgecho "using USER: $USER"

# Check if postfix master file has been modified
grep "wl2k" /etc/postfix/master.cf
if [ $? -ne 0 ] ; then
   {
      echo "wl2k      unix  -       n       n       -       1      pipe"
      echo "  flags=XFRhu user=$USER argv=/usr/local/libexec/mail.wl2k -m"
   } >> /etc/postfix/master.cf
else
   dbgecho " /etc/postfix/master.cf already modified."
fi

# Check if postfix main file has been modified

cat << EOT >> /etc/postfix/main.cf
transport_maps = hash:/etc/postfix/transport
smtp_host_lookup = dns, native
EOT

exit 0
