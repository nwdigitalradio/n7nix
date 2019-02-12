#!/bin/bash
#
# postfix_config.sh <user_name>
#
# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
pkg_name="postfix"
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
    # Is service alread running?
    systemctl is-active "$service"
    if [ "$?" -eq 0 ] ; then
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

echo -e "\n\tConfigure postfix\n"

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root."
   exit 1
fi

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

# if there are any args on command line assume it's a user name
if (( $# != 0 )) ; then
   USER="$1"
else
   get_user
fi

check_user

# Check if postfix has been installed
program_name="postfix"
type -P $program_name &>/dev/null
if [ $? -ne 0 ] ; then
   echo "$scriptname: No $program_name program found in path ... installing"
   # Program name & package name are the same
   apt-get install -y -q $program_name
else
   dbgecho "Program: $program_name  found"
fi

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

postfix_main_cfg_file="/etc/postfix/main.cf"
grep "transport_maps" "$postfix_main_cfg_file"
if [ $? -ne 0 ] ; then
    # Comment out previous 'inet_protocols =' entry
    sed -i -e "/^inet_protocols =/ s/^/# /" $postfix_main_cfg_file
    cat << EOT >> "$postfix_main_cfg_file"

inet_protocols = ipv4
transport_maps = hash:/etc/postfix/transport
smtp_host_lookup = dns, native
EOT
fi

POSTFIX_DESTINATION='$myhostname.localhost, $myhostname, localhost.localdomain, localhost'
sed -i -e "/mydestination = / s/mydestination =.*/mydestination=$POSTFIX_DESTINATION/" $postfix_main_cfg_file
sed -i -e "/myhostname = / s/myhostname = .*/myhostname = $(hostname).localnet/" $postfix_main_cfg_file
sed -i -e "/inet_protocols = / s/inet_protocols = .*/inet_protocols = ipv4/" $postfix_main_cfg_file

# Specify a pathname ending in "/" for qmail-style delivery.
# This needs to match mail client & dovecot configuration.
postconf -e "home_mailbox = Mail/"

# Make a transport file
{
echo "localhost     :"
echo "$(hostname)             local:"
echo "$(hostname).localnet    local:"
echo "$(hostname).localhost   local:"
echo "#"
echo "*         wl2k:localhost"
} > /etc/postfix/transport

# create transport database file
postmap /etc/postfix/transport

# create /etc/aliases
{
echo "# See man 5 aliases for format"
echo "postmaster:  $USER"
echo "root:  $USER"
echo "mailer-daemon:  $USER"
echo "nobody:  $USER"
} > /etc/aliases

newaliases

# restart postfix for new configuration to take affect
start_service postfix
systemctl --no-pager status postfix

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: postfix config script FINISHED" | tee -a $UDR_INSTALL_LOGFILE
echo
