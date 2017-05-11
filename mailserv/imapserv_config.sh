#!/bin/bash
#
# Uncomment this statement for debug echos
DEBUG=1

USER=pi
scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

# ===== main

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root."
   exit 1
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
grep "wl2k" /etc/postfix/master.cf  > /dev/null 2>&1
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
# Needs to match mail client config
home_mailbox = Mail/
EOT
fi

# Check if postfix sasl has already been configured
grep -i "smtpd_sasl_type = dovecot" /etc/postfix/main.cf > /dev/null 2>&1
if [ $? -eq 0 ] ; then
   echo "postscript sasl already configured."
else
   cat << EOT >> /etc/postfix/main.cf
# SASL parameters
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
EOT
fi

# Uncomment smtps
sed -i -e "/#smtps / s/^#//" /etc/postfix/master.cf
sed -i -e "/#  -o syslog_name=/ s/^#//" /etc/postfix/master.cf
sed -i -e "/#  -o smtpd_tls_wrappermode=/ s/^#//" /etc/postfix/master.cf

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

grep -i "#unix_listener \/var\/spool\/postfix\/private\/auth" /etc/dovecot/conf.d/10-master.conf  > /dev/null 2>&1
if [ $? -eq 0 ] ; then
   sed -i -e '/  # Postfix smtp-auth/a\
  unix_listener \/var\/spool\/postfix\/private\/auth {\
    mode = 0666\n    user = postfix\n    group = postfix\n   }\n' /etc/dovecot/conf.d/10-master.conf

   # delete the line with #unix_listener and the two lines following
   sed -i -e  "/#unix_listener \/var\/spool\/postfix\/private\/auth/,+2 d" /etc/dovecot/conf.d/10-master.conf
else
   echo "unix_listener already configured in /etc/dovecot/conf.d/10-master.conf"
fi
# Turn ssl on
sed -i -e "/ssl =/ s/ssl =.*/ssl = yes/" /etc/dovecot/conf.d/10-ssl.conf
sed -i -e "/#ssl_cert / s|#ssl_cert =.*|ssl_cert = </etc/ssl/certs/dovecot.pem|" /etc/dovecot/conf.d/10-ssl.conf
sed -i -e "/#ssl_key / s|#ssl_key =.*|ssl_key = </etc/ssl/private/dovecot.pem|" /etc/dovecot/conf.d/10-ssl.conf
sed -i -e "/#ssl_protocols =/ s/#ssl_protocols =.*/ssl_protocols = !SSLv2 !SSLv3/" /etc/dovecot/conf.d/10-ssl.conf

# uncomment listen config line
sed -i -e "/#listen / s/^#//" /etc/dovecot/dovecot.conf

### --- further postfix config
### --- NEED TO VERIFY
#postconf -e "mailbox_command = /usr/lib/dovecot/deliver"
systemctl restart postfix
systemctl restart dovecot

echo "$(date "+%Y %m %d %T %Z"): imapserv config script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "imapserv config FINISHED"
echo
