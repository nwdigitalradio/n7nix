#!/bin/bash
#
# Install all packages & programs required for:
#  direwolf, packet RMS Gateway, paclink-unix
#

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

# ===== main

echo "$(date "+%Y %m %d %T %Z"): $scriptname: image install script START" >> $UDR_INSTALL_LOGFILE
echo

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "$scriptname: Must be root"
   exit 1
fi

echo "$scriptname: Install direwolf & ax25 files"
./core_install.sh

echo "$scriptname: Install RMS Gateway"
pushd ../rmsgw
source ./install.sh
popd > /dev/null

echo "$scriptname: Install paclink-unix with imap"
pushd ../plu
source ./pluimap_install.sh
popd > /dev/null

echo "$(date "+%Y %m %d %T %Z"): $scriptname: image install script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "image install script FINISHED"
echo
