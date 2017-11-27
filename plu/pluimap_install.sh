#!/bin/bash
#
# Install paclink-unix (with postfix & mutt) hostapd & dovecot
#
# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

echo "$scriptname: paclink-unix with imap install"
echo "$scriptname: Install paclink-unix, hostapd, dovecot, node.js & systemd files"

# ===== Main

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root."
   exit 1
fi

# First install basic paclink-unix
./plu_install.sh

# Install dovecot imap mail server
pushd ../mailserv
source ./imapserv_install.sh
popd

# Install a host access point for remote operation
pushd ../hostap
source ./hostap_install.sh
popd

# Setup node.js & modules required to run the plu web page.
echo "$scriptname: Install nodejs, npm & jquery"

cd /usr/local/src/paclink-unix/webapp

apt-get install -y -q nodejs npm
npm install -g websocket connect finalhandler serve-static

# jquery should be installed in same directory as plu.html
npm install jquery
cp node_modules/jquery/dist/jquery.min.js jquery.js

# If there are any command line args do not install this service file
# A different service file is used to install paclink-unix with a
# tracker.
if( (( $# == 0 )) ; then
   echo "$scriptname: Install systemd files for paclink-unix web service."
   service_name="pluweb.service"
   # Setup systemd files for paclink-unix web server auto start
   if [ ! -f "/etc/systemd/system/$service_name" ] ; then
      echo "File /etc/systemd/system/$service_name DOES NOT EXIST"
   fi
fi

echo "$(date "+%Y %m %d %T %Z"): plu with imap install script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "paclink-unix with imap, install script FINISHED"
echo
