#!/bin/bash
#
# UNinstall current version of either:
#  dantracker or nixtracker
#
#
DEBUG=1
FORCE_BUILD="false"

scriptname="`basename $0`"

BIN_DIR_1="/usr/local/bin"

# tracker type can be either dan or nix
# nixtracker adds Winlink ability
tracker_type="nix"
#tracker_type="dan"

LIBFAP_SRC_DIR="$SRC_DIR/libfap"
JSON_C_SRC_DIR="$SRC_DIR/json-c"
LIBFAP_VER="1.5"
LIBINIPARSER_VER="3.1"
NODEJS_VER="8.4.0"

SERVICE_NAME="tracker.service"
BIN_FILES="tracker-up tracker-down tracker-restart .screenrc.trk"

# ===== function dbgecho

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# ===== function get_user
function get_user() {

# prompt for user name
# Check if there is only a single user on this system

USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

if (( `ls /home | wc -l` == 1 )) ; then
   USER=$(ls /home)
else
  echo "Enter user name ($(echo $USERLIST | tr '\n' ' ')), followed by [enter]:"
  read -e USER
fi

# verify user name is legit
userok=false

for username in $USERLIST ; do
  if [ "$USER" = "$username" ] ; then
     userok=true;
  fi
done

if [ "$userok" = "false" ] ; then
   echo "User name does not exist,  must be one of: $USERLIST"
   exit 1
fi

dbgecho "using USER: $USER"
}

# ===== main

# Don't be root
#if [[ $EUID == 0 ]] ; then
#   echo "Don't be root"
#   exit 1
#fi

echo "$scriptname: Install tracker with UID: $EUID"

get_user
SRC_DIR="/home/$USER/dev"
BIN_DIR="/home/$USER/bin"
TRACKER_N7NIX_DIR="/home/$USER/n7nix/tracker"

TRACKER_DEST_DIR="$BIN_DIR"
TRACKER_DEST_DIR_1="$BIN_DIR_1"
TRACKER_CFG_DIR="/etc/tracker"
TRACKER_SRC_DIR="$SRC_DIR/${tracker_type}tracker"

# Remove tracker source
if [ -d $TRACKER_SRC_DIR ] ; then
   rm -R $TRACKER_SRC_DIR
   echo "** tracker source directory: $TRACKER_SRC_DIR removed"
fi

if [ -d $SRC_DIR/libfap-$LIBFAP_VER ] ; then
   rm -R $SRC_DIR/libfap-$LIBFAP_VER
   echo "** libfap source directory: $SRC_DIR/libfap-$LIBFAP_VER removed"
fi

if [ -d $SRC_DIR/iniparser ] ; then
   rm -R $SRC_DIR/iniparser
   echo "** iniparser source directory: $SRC_DIR/iniparser removed"
fi

if [ -d $JSON_C_SRC_DIR ] && [ "$FORCE_BUILD" = "false" ]; then
   rm -R $JSON_C_SRC_DIR
   echo "** JSON_C source directory: $JSON_C_SRC_DIR removed"
fi

echo
echo "== remove ${tracker_type}tracker"

rm $TRACKER_DEST_DIR/aprs
sudo rm aprs  $TRACKER_DEST_DIR_1/aprs

rm -R $TRACKER_DEST_DIR/webapp

echo
echo "== remove files from bin dir"
for filename in `echo ${BIN_FILES}` ; do
   rm $BIN_DIR/$filename
done

if [ -f $TRACKER_CFG_DIR/aprs_tracker.ini ] ; then
   sudo rm $TRACKER_CFG_DIR/aprs_tracker.ini
fi

if [ -f /etc/systemd/system/$SERVICE_NAME ] ; then
  sudo systemctl stop $SERVICE_NAME
  sudo systemctl enable $SERVICE_NAME
  sudo rm /etc/systemd/system/$SERVICE_NAME
fi

echo "finished UNinstalling ${tracker_type}tracker"
