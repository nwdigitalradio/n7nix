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
    systemctl start "$service"
    if [ "$?" -ne 0 ] ; then
        echo "Problem starting $service"
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


# Edit these files in /etc/dovecot: dovecot.conf
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

# Edit these files in /etc/dovecot/conf.d
dovecot_cfg_dir="/etc/dovecot/conf.d"
dovecot_cfg_file="$dovecot_cfg_dir/10-auth.conf"
## disable_plaintext_auth = no
## auth_mechanisms = plain login
sed -i -e "/^[#]disable_plaintext_auth =/ s/disable_plaintest_auth =.*/disable_plaintest_auth = no/" $dovecot_cfg_file
sed -i -e "/auth_mechanisms =/ s/auth_mechanisms =.*/auth_mechanisms = plain login/" $dovecot_cfg_file

dovecot_cfg_file="$dovecot_cfg_dir/10-mail.conf"
## mail_location = maildir:~/Mail
## mail_privileged_group = mail
sed -i -e "/mail_location =/ s|mail_location =.*|mail_location = maildir:~/Mail|" $dovecot_cfg_file
sed -i -e "/auth_mechanisms =/ s/auth_mechanisms =.*/auth_mechanisms = plain login/" $dovecot_cfg_file

# 10-master.conf
## in service imap-login
##     port = 143
## inet_listener imaps
##     port = 993
##    ssl = yes

# Confirm dovecot is running
start_service "dovecot.service"

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: dovecot config FINISHED" | tee -a $UDR_INSTALL_LOGFILE
echo
