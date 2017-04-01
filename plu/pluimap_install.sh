#!/bin/bash
#
# Install paclink-unix (with postfix & mutt) hostapd & dovecot
#
# Uncomment this statement for debug echos
DEBUG=1

myname="`basename $0`"

echo "$myname: paclink-unix with imap install"
echo "$myname: Install paclink-unix, hostapd, dovecot & node.js"
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

apt-get install nodejs npm
npm install -g websocket connect finalhandler serve-static

# jquery should be installed in same directory as plu.html
npm install jquery
cp node_modules/jquery/dist/jquery.min.js jquery.js

echo
echo "$myname: NOTE: You need to start paclink-unix web server"
echo "$myname: As root cd /usr/local/src/paclink-unix/webapp then nodejs plu-server.js"
echo
echo "paclink-unix with imap, install script FINISHED"
echo
