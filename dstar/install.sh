#!/bin/bash
#
scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

START_DIR=$(pwd)

echo " === Install dstar repeater & ircddbgateway"
cd $START_DIR
cd ..
echo "Installing from this directory $(pwd)"

wget http://archive.compasslinux.org/pool/main/d/dstarrepeater/dstarrepeater_1.20180703-4_armhf.deb
wget http://archive.compasslinux.org/pool/main/d/dstarrepeater/dstarrepeaterd_1.20180703-4_armhf.deb
wget http://archive.compasslinux.org/pool/main/i/ircddbgateway/ircddbgateway_1.20180703-1_armhf.deb
wget http://archive.compasslinux.org/pool/main/i/ircddbgateway/ircddbgatewayd_1.20180703-1_armhf.deb

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: DStar install script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
echo
