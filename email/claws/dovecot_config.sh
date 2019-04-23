#!/bin/bash
#
# dovecot_config.sh [user_name]
#
# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
USER=

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# ===== function get_user

function get_user() {
   # Check if there is only a single user on this system
   if (( `ls /home | wc -l` == 1 )) ; then
      USER=$(ls /home)
   else
      echo "Enter user name ($(echo $USERLIST | tr '\n' ' ')), followed by [enter]:"
      read -e USER
   fi
}

# ==== function check_user
# verify user name is legit

function check_user() {
   userok=false
   dbgecho "$scriptname: Verify user name: $USER"
   for username in $USERLIST ; do
      if [ "$USER" = "$username" ] ; then
         userok=true;
      fi
   done

   if [ "$userok" = "false" ] ; then
      echo "User name ($USER) does not exist,  must be one of: $USERLIST"
      exit 1
   fi

   dbgecho "using USER: $USER"
}

# ===== function start_service

function start_service() {
    service="$1"
    systemctl is-enabled "$service" > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "ENABLING $service"
        systemctl enable "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem ENABLING $service"
        fi
    fi
    # Is service alread running?
    if systemctl is-active --quiet "$service" ; then
        # service is already running, restart it to update config changes
        systemctl --no-pager restart "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem re-starting $service"
        fi
    else
        # service is not yet running so start it up
        systemctl --no-pager start "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem starting $service"
        fi
    fi
}

# ===== main

echo -e "\n\tConfigure dovecot\n"

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "$scriptname: Must be root"
   exit 1
fi

# Check for any arguments
if (( $# != 0 )) ; then
   USER="$1"
fi

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

# Check if user name was supplied on command line
if [ -z "$USER" ] ; then
    # prompt for call sign & user name
    # Check if there is only a single user on this system
    get_user
fi
# Verify user name
check_user

pkg_name="dovecot-core"
is_pkg_installed $pkg_name
if [ $? -ne 0 ] ; then
    echo "$scriptname: Will Install $pkg_name package"
    apt-get install -y -q $pkg_name
fi

pkg_name="dovecot-imapd"
is_pkg_installed $pkg_name
if [ $? -ne 0 ] ; then
    echo "$scriptname: Will Install $pkg_name package"
    apt-get install -y -q $pkg_name
fi

# ===== Edit this file in /etc/dovecot: dovecot.conf =====
dovecot_cfg_dir="/etc/dovecot"
dovecot_cfg_file="$dovecot_cfg_dir/dovecot.conf"

## listen = *
sed -i -e "/^[#]listen =/ s/^[#]listen =.*/listen = \*/" $dovecot_cfg_file
cat << EOT >> $dovecot_cfg_file

protocol lda {
postmaster_address = $USER@$(hostname)
}
auth_debug_passwords=yes
EOT

# ===== Edit these files in /etc/dovecot/conf.d =====
# ==== 10-auth` ====
dovecot_cfg_dir="/etc/dovecot/conf.d"
dovecot_cfg_file="$dovecot_cfg_dir/10-auth.conf"

## disable_plaintext_auth = no
## auth_mechanisms = plain login
sed -i -e "/^[#]disable_plaintext_auth =/ s/disable_plaintext_auth =.*/disable_plaintext_auth = no/" $dovecot_cfg_file
sed -i -e "/auth_mechanisms =/ s/auth_mechanisms =.*/auth_mechanisms = plain login/" $dovecot_cfg_file

# ==== 10-mail ====
dovecot_cfg_file="$dovecot_cfg_dir/10-mail.conf"

# Comment out any mail_location lines
sed -i -e "/^mail_location =/ s/^/# /" $dovecot_cfg_file

#sed -i -e "/mail_location =/ s|mail_location =.*|mail_location = maildir:~/Mail|" $dovecot_cfg_file
#sed -i -e 's|^[#]mail_location = |mail_location = maildir:~/Mail\n&|'  $dovecot_cfg_file
#awk 'FNR==NR{ if (/mail_location =/) p=NR; next} 1; FNR==p{ print "mail_location = maildir:~/Mail\n" }' $dovecot_cfg_file $dovecot_cfg_file

# Set new mail_location by adding line after last occurrence of 'mail_location = '
sed -i -e '/mail_location = [^\n]*/,$!b;//{x;//p;g};//!H;$!d;x;s//&\nmail_location = maildir:~\/Mail/' $dovecot_cfg_file

## mail_privileged_group = mail
sed -i -e "/^[#]mail_privileged_group =/ s/^[#]mail_privileged_group =.*/mail_privileged_group = mail/" $dovecot_cfg_file

# ==== 10-master ====
dovecot_cfg_file="$dovecot_cfg_dir/10-master.conf"
## in service imap-login
##     port = 143
sed -i -e "/#port = 143/ s/#port = 143/port = 143/" $dovecot_cfg_file
## inet_listener imaps
##     port = 993
##    ssl = yes
sed -i -e "/#port = 993/ s/#port = 993/port = 993/" $dovecot_cfg_file

# Search for 'ssl =' after service imap login
imapssl_line=$(grep -A 15 -i "service imap-login" $dovecot_cfg_file | grep -i "ssl = " | sed 's/^ *//')

echo "imap ssl line: $imapssl_line"

if [[ "${imapssl_line:0:1}" == "#" ]] ; then
    echo " Found comment character in first char of line: $imapssl_line"
else
    echo " Commenting imap ssl line."
#    sed -i '/ssl =/ s/\(^.*ssl = .*$\)/#\ \1/' $dovecot_cfg_file
    sed -i '0,/ssl =/ s/\(.*ssl = .*$\)/#\ \1/' $dovecot_cfg_file
fi
# grep -i "ssl =" $dovecot_cfg_file

# restart dovecot for new configuration to take affect
start_service dovecot
systemctl --no-pager status postfix

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: dovecot config FINISHED" | tee -a $UDR_INSTALL_LOGFILE
echo
