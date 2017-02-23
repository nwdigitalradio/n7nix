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

# ===== main

if [ ! -f /etc/mailname ] ; then
   echo "$(hostname).localdomain" > /etc/mailname
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
  read -e USER
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

### Configure postfix

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
grep -i "smtp_host_lookup = dns, native" /etc/postfix/main.cf > /dev/null 2>&1
if [ $? -eq 0 ] ; then
   echo "main.cf already configured."
else
   cat << EOT >> /etc/postfix/main.cf
transport_maps = hash:/etc/postfix/transport
smtp_host_lookup = dns, native
EOT
fi

### Configure dovecot

echo "Editing dovecot configuration files"
# Check if dovecot ssl cert has been created
if [ ! -f /etc/ssl/certs/dovecot.pem ] ; then
   openssl req -new -x509 -nodes -out /etc/ssl/certs/dovecot.pem -keyout /etc/ssl/private/dovecot.pem -days 5000
fi

# modify dovecot config files
sed -i -e "/auth_mechanisms =/ s/auth_mechanisms =.*/auth_mechanisms = plain login/" /etc/dovecot/conf.d/10-auth.conf
sed -i -e "/disable_plaintext_auth/ s/#disable_plaintext_auth =.*/disable_plaintext_auth = no/" /etc/dovecot/conf.d/10-auth.conf

# Only edit line if it is not a comment
sed -i -e "/^mail_location/ s|mail_location =.*|mail_location = maildir:~/Mail|" /etc/dovecot/conf.d/10-mail.conf
sed -i -e "/mail_privileged_group =/ s/#mail_privileged_group =.*/mail_privileged_group = mail/" /etc/dovecot/conf.d/10-mail.conf

# For service imap-login
sed -i -e "/port = 143/ s/#port = 143/port = 143/" /etc/dovecot/conf.d/10-master.conf
sed -i -e "/port = 993/ s/#port = 993/port = 993/" /etc/dovecot/conf.d/10-master.conf
sed -i -e "/inet_listener imaps {/,/}/ s/#ssl =.*/ssl = yes/" /etc/dovecot/conf.d/10-master.conf
# Might have to configure a unix_listener for postfix smtp-auth

# Turn ssl on
sed -i -e "/ssl =/ s/ssl =.*/ssl = yes/" /etc/dovecot/conf.d/10-ssl.conf
sed -i -e "|#ssl_cert| s|#ssl_cert =.*|/etc/ssl/certs/dovecot.pem|" /etc/dovecot/conf.d/10-ssl.conf
sed -i -e "|#ssl_key| s|#ssl_key =.*|/etc/ssl/private/dovecot.pem|" /etc/dovecot/conf.d/10-ssl.conf
sed -i -e "/#ssl_protocols =/ s/#ssl_protocols =.*/ssl_protocols = !SSLv2 !SSLv3/" /etc/dovecot/conf.d/10-ssl.conf

# uncomment listen config line
sed -i -e "/#listen / s/^#//" /etc/dovecot/dovecot.conf

### --- further postfix config
### --- NEED TO VERIFY
#postconf -e "mailbox_command = /usr/lib/dovecot/deliver"
#systemctl restart postfix

echo
echo "imapserv install & config FINISHED"
echo
