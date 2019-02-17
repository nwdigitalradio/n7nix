#!/bin/bash
#
# Install paclink-unix with postfix, dovecot, mutt, claws-mail, hostapd
# & paclink-unix web app
#
# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

echo "$scriptname: paclink-unix with imap install"
echo "$scriptname: Install paclink-unix, hostapd, dovecot, node.js & systemd files"

# Define conditional for installing messanger
messanger="false"

# ===== Main

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root."
   exit 1
fi

# Check for command line arguments
if (( $# > 0 )) ; then
   echo "$scriptname: detected command line arguments"
   echo "Not installing hostapd & pluweb.service file"
   messanger="true"
fi

# First install basic paclink-unix
# This installs postfix dovecot mutt & claws-mail
./plu_install.sh

# Install postfix dovecot-core dovecot-imapd telnet
# This is not needed anymore as it is done int the basic plu install
#pushd ../mailserv
#source ./imapserv_install.sh
#popd

if [ "$messanger" == "false" ] ; then
   # Install a host access point for remote operation
   pushd ../hostap
   source ./hostap_install.sh
   popd
fi

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
if [ "$messanger" == "false" ] ; then
    # This sets up systemd to start web server for paclink-unix
    source ./pluweb_install.sh
else
    echo "$scriptname: Using systemd files from messanger install"
fi

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: paclink-unix with imap install script FINISHED" | tee -a $UDR_INSTALL_LOGFILE
echo
