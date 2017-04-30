#!/bin/bash
#
# Install paclink-unix (with postfix & mutt) hostapd & dovecot
#
# Uncomment this statement for debug echos
DEBUG=1

myname="`basename $0`"

echo "$myname: paclink-unix with imap install"
echo "$myname: Install paclink-unix, hostapd, dovecot, node.js & systemd files"
# First install basic paclink-unix
./plu_install.sh

# Install dovecot imap mail server
pushd ../mailserv
source ./imapserv_install.sh
popd

# Set up a host access point for remote operation
pushd ../hostap
source ./hostap_install.sh
popd

# Setup node.js & modules required to run the plu web page.
echo "$myname: Install nodejs, npm & jquery"

cd /usr/local/src/paclink-unix/webapp

apt-get install -y -q nodejs npm
npm install -g websocket connect finalhandler serve-static

# jquery should be installed in same directory as plu.html
npm install jquery
cp node_modules/jquery/dist/jquery.min.js jquery.js

echo "$myname: Install systemd files for paclink-unix web service."
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

echo
echo "paclink-unix with imap, install script FINISHED"
echo
