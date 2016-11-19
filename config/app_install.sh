#!/bin/bash
#
# Expects an argument for which app to install
# Arg can be one of the following:
#	core, rmsgw, plu, pluimap
#
# Uncomment this statement for debug echos
DEBUG=1

myname="`basename $0`"
CALLSIGN="N0ONE"
APP_CHOICES="core, rmsgw, plu, pluimap"
APP_SELECT="rmsgw"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function get_callsign

function get_callsign() {

if [ "$CALLSIGN" == "N0ONE" ] ; then
   echo "Enter call sign, followed by [enter]:"
   read CALLSIGN

   sizecallstr=${#CALLSIGN}

   if (( sizecallstr > 6 )) || ((sizecallstr < 3 )) ; then
      echo "Invalid call sign: $CALLSIGN, length = $sizecallstr"
      exit 1
   fi

   # Convert callsign to upper case
   CALLSIGN=$(echo "$CALLSIGN" | tr '[a-z]' '[A-Z]')
fi

dbgecho "Using CALL SIGN: $CALLSIGN"
}

# ===== main

echo "$myname script start"

# make sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "$myname: Must be root"
   exit 1
fi

# Check if there are any args on command line
if (( $# != 0 )) ; then
   APP_SELECT=$1
   # check argument passed to this script
   case $1 in
   core)
      echo "$myname: core"
   ;;
   rmsgw)
      echo "$myname: rmsgw"
   ;;
   plu)
      echo "$myname: paclink-unix"
   ;;
   pluimap)
      echo "$myname: paclink-unix imap"
   ;;
   *)
      echo "Undefined app, must be one of $APP_CHOICES"
      exit 1
   ;;
   esac
else
   echo "No app chosen, so installing RMS Gateway"
fi

# prompt for a valid callsign
get_callsign

# configure ax25
echo "Configure ax.25"
# Needs a callsign
source ../ax25/install.sh $CALLSIGN

# configure direwolf
# Needs a callsign
pushd ../direwolf
source ./install.sh $CALLSIGN
popd

# configure systemd
pushd ../systemd
/bin/bash ./install.sh
popd


   # check argument passed to this script
case $APP_SELECT in
   core)
      echo "core application install FINISHED"
   ;;
   rmsgw)
      # install rmsgw
      echo "Install RMS Gateway"
      pushd ../rmsgw
      source ./install.sh
      popd

      # configure rmsgw
      echo "Configure RMS Gateway"
      # needs a callsign
      source ../rmsgw/config.sh $CALLSIGN
   ;;
   plu)
      # install paclink-unix basic
      echo "Install paclink-unix"
      pushd ../plu
      source ./plu_install.sh
      popd

   ;;
   pluimap)
   ;;
   *)
      echo "Undefined app, must be one of $APPCHOICES"
      exit 1
   ;;
esac

UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
echo "$(date "+%Y %m %d %T %Z"): app install ($APP_SELECT) script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "app install script FINISHED"
echo
