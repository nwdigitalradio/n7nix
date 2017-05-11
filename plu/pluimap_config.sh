#!/bin/bash
#
# Configure paclink-unix (with postfix & mutt) hostapd & dovecot
#
# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

# ===== Main

echo "$scriptname: paclink-unix with imap configure"
echo "$scriptname: Config paclink-unix, hostapd, dovecot, node.js & systemd files"

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root."
   exit 1
fi

# First configure basic paclink-unix
./plu_config.sh

# Config dovecot imap mail server
pushd ../mailserv
source ./imapserv_config.sh
popd

# Set up a host access point for remote operation
pushd ../hostap
source ./hostap_config.sh
popd

echo "$scriptname: Install systemd files for paclink-unix web service."
service_name="pluweb.service"
# Setup systemd files for paclink-unix web server auto start
if [ ! -f "/etc/systemd/system/$service_name" ] ; then
   echo "File /etc/systemd/system/$service_name DOES NOT EXIST"
   exit 1
fi

systemctl enable $service_name
systemctl daemon-reload
systemctl start $service_name

echo
echo "Check that $service_name is running."

systemctl is-active $service_name >/dev/null
if [ "$?" = "0" ] ; then
   echo "$service_name is running!"
else
   echo "ERROR: $service_name did NOT start."
fi

echo "$(date "+%Y %m %d %T %Z"): plu with imap config script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "paclink-unix with imap, config script FINISHED"
echo
