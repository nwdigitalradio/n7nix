#!/bin/bash
#
# Expects an argument for which app to install
# Arg can be one of the following:
#	core, rmsgw, plu, pluimap
#
# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

CALLSIGN="N0ONE"
APP_CHOICES="core, rmsgw, plu, pluimap, uronode"
APP_SELECT="rmsgw"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== main

echo "$scriptname: script start"

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "$scriptname: Must be root"
   exit 1
fi

# Check if there are any args on command line
if (( $# != 0 )) ; then
   APP_SELECT=$1
else
   echo "No app chosen from command arg, so installing RMS Gateway"
fi

   # check argument passed to this script
case $APP_SELECT in
   core)
      echo "$scriptname: Install core"

      # install systemd files
      pushd ../systemd
      /bin/bash ./install.sh
      popd > /dev/null

      echo "core installation FINISHED"
   ;;
   rmsgw)
      echo "$scriptname: Install RMS Gateway"
      # install rmsgw
      pushd ../rmsgw
      source ./install.sh
      popd > /dev/null
   ;;
   plu)
      # install paclink-unix basic
      echo "$scriptname: Install paclink-unix"
      pushd ../plu
      source ./plu_install.sh
      popd > /dev/null

   ;;
   pluimap)
#      echo "$scriptname: Install paclink-unix with imap"
      echo  "$scriptname: pluimap is under development, just use 'plu'"
      pushd ../plu

      source ./plu_install.sh

      popd > /dev/null
   ;;
   uronode)
      echo "$scriptname: Install uronode"
      pushd ../uronode
      source ./uro_install.sh
      popd > /dev/null
   ;;
   tracker)
      echo "$scriptname: Install tracker (nix or dan)"
      pushd ../tracker
      source ./tracker_install.sh
      popd > /dev/null
   ;;
   messanger)
   # Install pluimap & nixtracker
      echo "$scriptname: Install messanger appliance"
      pushd ../plu
      # Command line arg prevents installation of pluweb.service
      source ./pluimap_install.sh -
      popd > /dev/null
      pushd ../tracker
      echo "Change to normal login user & cd to ~/n7nix/tracker"
      echo " then run tracker_install.sh"

##      source ./tracker_install.sh
      popd > /dev/null
   ;;

   *)
      echo "Undefined app, must be one of $APP_CHOICES"
      echo "$(date "+%Y %m %d %T %Z"): app install ($APP_SELECT) script ERROR, undefined app" >> $UDR_INSTALL_LOGFILE
      exit 1
   ;;
esac

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: app install ($APP_SELECT) script FINISHED" | tee -a  $UDR_INSTALL_LOGFILE
echo
