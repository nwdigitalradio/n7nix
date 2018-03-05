#!/bin/bash
#
# Configure paclink-unix (with postfix & mutt) hostapd & dovecot
#
# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

# Define conditional for installing messanger
messanger="false"

# ===== function systemservice_start

function systemservice_start() {
   systemctl enable $1
   systemctl daemon-reload
   systemctl start $1
}

# ===== Main

echo "$scriptname: paclink-unix with imap configure"
echo "$scriptname: Config paclink-unix, hostapd, dovecot, node.js & systemd files"

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root."
   exit 1
fi

# Check for command line arguments
if (( $# > 0 )) ; then
   echo "$scriptname: detected command line arguments"
   echo "Not configuring hostapd & pluweb.service file"
   messanger="true"
fi

# First configure basic paclink-unix
./plu_config.sh

# Config dovecot imap mail server
pushd ../mailserv
source ./imapserv_config.sh
popd

if [ "$messanger" == "false" ] ; then
   # Set up a host access point for remote operation
   echo "=== Config hostap"
   pushd ../hostap
   source ./hostap_config.sh
   popd
fi

echo "$scriptname: Start systemd service for paclink-unix web service."
service_name=
# Setup systemd files for paclink-unix web server auto start
if [ -f "/etc/systemd/system/pluweb.service" ] ; then
   service_name="pluweb.service"
   systemservice_start "$service_name"
elif [ -f "/etc/systemd/system/tracker.service" ] ; then
   service_name="tracker.service"
   systemservice_start "$service_name"
else
   echo
   echo "No systemd service file found for starting paclink-unix web app."
   echo
fi

if [ ! -z $service_name ] ; then
   echo
   echo "Check that $service_name is running."

   systemctl is-active $service_name >/dev/null
   if [ "$?" = "0" ] ; then
      echo "$service_name is running!"
   else
      echo "ERROR: $service_name did NOT start."
   fi
fi

echo "$(date "+%Y %m %d %T %Z"): $scriptname: plu with imap config script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "paclink-unix with imap, config script FINISHED"
echo
