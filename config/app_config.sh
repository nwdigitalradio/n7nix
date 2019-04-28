#!/bin/bash
#
# Expects an argument for which app to install
# Arg can be one of the following:
#	core, rmsgw, plu, pluimap
#
# Uncomment this statement for debug echos
# DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

CALLSIGN="N0ONE"
USER=
APP_CHOICES="core, rmsgw, plu, test"
APP_SELECT=

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function usage
function usage() {
   echo "Usage: $scriptname [-d][-h][core][plu][rmsgw][messanger]" >&2
   echo "   core      MUST be run before any other config"
   echo "   plu       Configures paclink-unix & email applications"
   echo "   rmsgw     Configures Linux RMS Gateway"
   echo "   messanger Configures messanger appliance"
   echo "   -d        set debug flag"
   echo "   -h        no arg, display this message"
   echo
}

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
# ===== function get_user

function get_user() {
   # Check if there is only a single user on this system
   if (( `ls /home | wc -l` == 1 )) ; then
      USER=$(ls /home)
   else
      echo "Enter user name ($(echo $USERLIST | tr '\n' ' ')), followed by [enter]:"
      read -e USER
   fi
}

# ==== function check_user
# verify user name is legit

function check_user() {
   userok=false
   dbgecho "$scriptname: Verify user name: $USER"
   for username in $USERLIST ; do
      if [ "$USER" = "$username" ] ; then
         userok=true;
      fi
   done

   if [ "$userok" = "false" ] ; then
      echo "User name ($USER) does not exist,  must be one of: $USERLIST"
      exit 1
   fi

   dbgecho "using USER: $USER"
}

# ===== main

echo "$scriptname: script start"

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "$scriptname: Must be root"
   exit 1
fi

# Check if there are any args on command line
if (( $# == 0 )) ; then
    echo "No app chosen from command arg, exiting"
    usage
    exit 1
fi

# check for control arguments passed to this script

APP_SELECT="$1"

while [[ $# -gt 0 ]] ; do
APP_ARG="$1"

case $APP_ARG in

   -d|--debug)
      DEBUG=1
      echo "Debug mode on"
   ;;
   -h|--help|?)
      usage
      exit 0
   ;;
   *)
      break;
   ;;

esac

shift # past argument
done

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

get_user
check_user

# Check again if there are any remaining args on command line
if (( $# == 0 )) ; then
    echo "No app chosen from command arg, exiting"
    usage
    exit 1
fi

# Get call sign if not doing a test
if [ "$APP_SELECT" != "test" ] ; then
    # prompt for a callsign
    while get_callsign ; do
        echo "Input error, try again"
    done
fi

# parse command args for app to config

while [[ $# -gt 0 ]] ; do
APP_SELECT="$1"

case $APP_SELECT in

   core)
      echo "$scriptname: Config core"
      # configure core
      source ./core_config.sh

      # configure ax25
      # Needs a callsign
      pushd ../ax25
      source ./config.sh $USER $CALLSIGN
      popd > /dev/null

      # configure direwolf
      # Needs a callsign
      pushd ../direwolf
      source ./config.sh $CALLSIGN
      popd > /dev/null

      # configure systemd
      pushd ../systemd
      /bin/bash ./install.sh
      /bin/bash ./config.sh
      popd > /dev/null

      # configure iptables
      pushd ../iptables
      /bin/bash ./iptable_install.sh $USER
      popd > /dev/null

      echo "core configuration FINISHED"
   ;;
   rmsgw)
      # Configure rmsgw
      echo "Configure RMS Gateway"
      # needs a callsign
      source ../rmsgw/config.sh $CALLSIGN
   ;;
   plu)
      # Configure paclink-unix basic
      # This configures mutt & postfix
      echo "$scriptname: Config paclink-unix"
      pushd ../plu
      source ./plu_config.sh $USER $CALLSIGN
      popd > /dev/null

      # This installs claws-mail & dovecot
      pushd ../email/claws
      sudo -u "$USER" ./claws_install.sh $USER $CALLSIGN
      popd > /dev/null

      # This sets up systemd to start web server for paclink-unix
      pushd ../plu
      source ./pluweb_install.sh $USER
      popd > /dev/null

      # This installs rainloop & lighttpd
      pushd ../email/rainloop
      source ./rainloop_install.sh
      popd > /dev/null
   ;;
   pluimap)
#      echo "$scriptname: Config paclink-unix with imap"
      echo  "$scriptname: pluimap is under development, just use 'plu'"
      pushd ../plu

#      source ./pluimap_config.sh
     source ./plu_config.sh $USER $CALLSIGN

      popd > /dev/null
   ;;
   messanger)
      echo "$scriptname: Config messanger appliance"
      pushd ../plu
      source ./pluimap_config.sh -
      popd > /dev/null
   ;;
   test)
      echo
      echo " ===== $scriptname: Test setting up AX.25 IP Address"
      echo
      source ./setax25-ipaddr.sh
   ;;
   *)
      echo "Undefined app, must be one of $APP_CHOICES"
      echo "$(date "+%Y %m %d %T %Z"): app install ($APP_SELECT) script ERROR, undefined app" >> $UDR_INSTALL_LOGFILE
      exit 1
   ;;
esac

shift # past argument or value
done

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: app config ($APP_SELECT) script FINISHED" | tee -a $UDR_INSTALL_LOGFILE
echo
