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

# ===== function get_callsign

function get_callsign() {

if [ "$CALLSIGN" == "N0ONE" ] ; then
   read -t 1 -n 10000 discard
   echo "Enter call sign, followed by [enter]:"
   read -e CALLSIGN

   sizecallstr=${#CALLSIGN}

   if (( sizecallstr > 6 )) || ((sizecallstr < 3 )) ; then
      echo "Invalid call sign: $CALLSIGN, length = $sizecallstr"
      return 0
   fi

   # Convert callsign to upper case
   CALLSIGN=$(echo "$CALLSIGN" | tr '[a-z]' '[A-Z]')
fi

dbgecho "Using CALL SIGN: $CALLSIGN"
return 1
}

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
      echo "$scriptname: Config core"
      # prompt for a valid callsign
      while get_callsign ; do
         echo "Input error, try again"
      done

      # configure ax25
      # Needs a callsign
      source ../ax25/config.sh $CALLSIGN

      # configure direwolf
      # Needs a callsign
      pushd ../direwolf
      source ./config.sh $CALLSIGN
      popd > /dev/null

      # configure systemd
      pushd ../systemd
      /bin/bash ./config.sh
      popd > /dev/null

      echo "core configuration FINISHED"
   ;;
   rmsgw)
      # configure rmsgw
      echo "Configure RMS Gateway"
      # needs a callsign
      source ../rmsgw/config.sh $CALLSIGN
   ;;
   plu)
      # install paclink-unix basic
      echo "$scriptname: Install paclink-unix"
      pushd ../plu
      source ./plu_config.sh
      popd > /dev/null

   ;;
   pluimap)
      echo "$scriptname: Install paclink-unix with imap"

      pushd ../plu
      source ./pluimap_config.sh
      popd > /dev/null
   ;;
   *)
      echo "Undefined app, must be one of $APPCHOICES"
      echo "$(date "+%Y %m %d %T %Z"): app install ($APP_SELECT) script ERROR, undefined app" >> $UDR_INSTALL_LOGFILE
      exit 1
   ;;
esac

echo "$(date "+%Y %m %d %T %Z"): app config ($APP_SELECT) script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "app config ($APP_SELECT) script FINISHED"
echo
