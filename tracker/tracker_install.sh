#!/bin/bash
#
# Install current version of either:
#  dantracker or nixtracker
#
# Builds:
#   - libiniparser
#   - libfap
#   - json-c
#   - dantracker or nixtracker
#
# How to install latest version of node
# https://nodejs.org/en/download
#
DEBUG=1
FORCE_BUILD="false"

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
USER=$(whoami)

SRC_DIR="/home/$USER/dev"
LOCAL_BIN_DIR="/home/$USER/bin"
GLOBAL_BIN_DIR="/usr/local/bin"
c
# tracker type can be either dan or nix
# nixtracker adds Winlink ability
tracker_type="nix"
#tracker_type="dan"

TRACKER_CFG_DIR="/etc/tracker"
TRACKER_CFG_FILE="$TRACKER_CFG_DIR/aprs_tracker.ini"
TRACKER_SRC_DIR="$SRC_DIR/${tracker_type}tracker"
TRACKER_N7NIX_DIR="/home/$USER/n7nix/tracker"

LIBFAP_SRC_DIR="$SRC_DIR/libfap"
JSON_C_SRC_DIR="$SRC_DIR/json-c"
LIBFAP_VER="1.5"
LIBINIPARSER_VER="3.1"
NODEJS_VER="10.15.2"

BIN_FILES="tracker-ctrl.sh tracker-up tracker-down tracker-restart .screenrc.trk"
PKGLIST="build-essential pkg-config imagemagick automake autoconf libtool libgps-dev screen nodejs npm git"

# ===== function dbgecho

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# ===== function get_callsign
# Default callsign in config template is 'NOCALL'

function get_callsign() {

if [ "$CALLSIGN" == "NOCALL" ] ; then
   echo "Enter call sign, followed by [enter]:"
   read -e CALLSIGN

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

# ===== function start_service

function start_service() {
    service="$1"
    systemctl is-enabled "$service" > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "ENABLING $service"
        systemctl enable "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem ENABLING $service"
        fi
    fi
    # Is service alread running?
    systemctl is-active "$service"
    if [ "$?" -eq 0 ] ; then
        # service is already running, restart it to update config changes
        systemctl --no-pager restart "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem re-starting $service"
        fi
    else
        # service is not yet running so start it up
        systemctl --no-pager start "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem starting $service"
        fi
    fi
}

# ===== main

# Don't be root
if [[ $EUID == 0 ]] ; then
   echo "Don't be root"
   exit 1
   # Switching users has problems
   get_user
   exec su "$USER" "$0" "$@"
fi

echo "$scriptname: Install tracker with UID: $EUID"


if [ ! -d $SRC_DIR ] ; then
   mkdir -p $SRC_DIR
fi

# Need to get tracker source before building libfap
if [ -d $TRACKER_SRC_DIR ] ; then
   echo "** already have tracker source"
else
   echo
   echo "== get ${tracker_type}tracker source"
   cd $SRC_DIR
   git clone https://github.com/n7nix/${tracker_type}tracker
fi

# as root install a bunch of stuff
sudo apt-get install -y -q $PKGLIST

node_file_name="node-v$NODEJS_VER-linux-armv7l.tar.xz"
echo
echo "== get node modules"
sudo npm -g install ctype iniparser connect serve-static finalhandler uid-number
sudo npm --unsafe-perm -g install websocket

#
# Do not do this!
#
GET_NODEJS=false

if $GET_NODEJS ; then
    if [ ! -f $node_file_name ] ; then
        echo "Download node.js from nodejs.org"
        wget https://nodejs.org/dist/v$NODEJS_VER/$node_file_name
        current_dir=$(pwd)
        pushd /usr/local
        sudo tar --strip-components 1 -xvf $current_dir/$node_file_name
        echo "node version: $(/usr/local/bin/node -v)"
        echo "npm version: $(/usr/local/bin/npm -v)"
        cd
    else
        echo "** already have nodejs source"
    fi
fi # GET_NODEJS

if [ -d $SRC_DIR/libfap-$LIBFAP_VER ] ; then
   echo "** already have libfap-$LIBFAP_VER source"
else
   echo
   echo "== get libfap source"
   # Get libfap [http://pakettiradio.net/libfap/]
   # To get latest version, index of downloads is here:
   # http://www.pakettiradio.net/downloads/libfap/

   cd $SRC_DIR
   wget http://pakettiradio.net/downloads/libfap/$LIBFAP_VER/libfap-$LIBFAP_VER.tar.gz
   tar -zxvf libfap-$LIBFAP_VER.tar.gz

   echo
   echo "== build libfap"
   # run the fap patch
   cd libfap-$LIBFAP_VER
   patch -p2 < $TRACKER_SRC_DIR/fap_patch.n7nix
   sudo cp src/fap.h /usr/local/include/
   ./configure
   make
   sudo make install
fi

if [ -d $SRC_DIR/iniparser ] ; then
   echo "** already have iniparser source"
else
   echo
   echo "== get libiniparser source"
   cd $SRC_DIR
   wget http://ndevilla.free.fr/iniparser/iniparser-$LIBINIPARSER_VER.tar.gz
   tar -zxvf iniparser-$LIBINIPARSER_VER.tar.gz
   echo
   echo "== build libiniparser source"
   cd iniparser
   sudo cp src/iniparser.h  /usr/local/include
   sudo cp src/dictionary.h /usr/local/include
   make
   sudo cp libiniparser.* /usr/local/lib
fi

if [ -d $JSON_C_SRC_DIR ] && [ "$FORCE_BUILD" = "false" ]; then
   echo "** already have json-c source"
else

   echo
   echo "== get json-c"
   cd $SRC_DIR

   #  https://github.com/json-c/json-c
   git clone git://github.com/json-c/json-c.git

   echo "== build json-c"
   mkdir json-c-build
   cd json-c-build
   cmake ../json-c   # See CMake section below for custom arguments
   make
   make test
   sudo make install
   sudo ldconfig
fi

# if /usr/local/include/json does not exist create a symbolic link
if [ ! -d /usr/local/include/json ] ; then
   sudo ln -s /usr/local/include/json-c /usr/local/include/json
fi

# Check if tracker has been built yet
if [ -f $TRACKER_SRC_DIR/aprs ] ; then
   echo "** already built tracker"
else
   echo
   echo "== build ${tracker_type}tracker"
   cd $TRACKER_SRC_DIR
   make
fi

# Check if /home/$USER/bin is a file
if [ -f $LOCAL_BIN_DIR ] ; then
   rm $LOCAL_BIN_DIR
fi

# Verify local bin dir
if [ ! -d $LOCAL_BIN_DIR ] ; then
   mkdir -p $LOCAL_BIN_DIR
fi

echo
echo "== install ${tracker_type}tracker"

   cd $TRACKER_SRC_DIR
   cp scripts/* $LOCAL_BIN_DIR

   # Fix this
   cp aprs  $LOCAL_BIN_DIR
   sudo cp aprs  $GLOBAL_BIN_DIR

   # Copy webapp files
   rsync -av $TRACKER_SRC_DIR/webapp $LOCAL_BIN_DIR
   rsync -av $TRACKER_SRC_DIR/images $LOCAL_BIN_DIR/webapp
   if [ ! -d $LOCAL_BIN_DIR/webapp/jQuery ] ; then
      mkdir -p $LOCAL_BIN_DIR/webapp/jQuery
   fi

   # Requirement that jquery directory is relative to web app location??
   cd $LOCAL_BIN_DIR/webapp/jQuery
   wget https://code.jquery.com/jquery-3.2.1.min.js
   mv jquery-3.2.1.min.js jquery.js

# This overwrites some of the ${tracker_type}tracker scripts from the n7nix repo
echo
echo "== setup bin dir"

# For screen only
cp $TRACKER_N7NIX_DIR/.${tracker_type}screenrc.trk $TRACKER_N7NIX_DIR/.screenrc.trk

# This will copy tracker-ctrl.sh to be used later to update systemd
# service files
for filename in `echo ${BIN_FILES}` ; do
   cp $TRACKER_N7NIX_DIR/$filename $LOCAL_BIN_DIR
done

sed -i -e "s/\$user/$USER/" $LOCAL_BIN_DIR/tracker-up
sed -i -e "s/\$user/$USER/" $LOCAL_BIN_DIR/tracker-restart

if [ ! -d $TRACKER_CFG_DIR ] ; then
   sudo mkdir -p $TRACKER_CFG_DIR
fi

# If config file does not exist copy template to /etc/tracker
if [ -f $TRACKER_CFG_FILE ] ; then
   echo "** tracker already config'ed in $TRACKER_CFG_DIR"
   echo "** please edit manually."
else
   sudo cp $TRACKER_N7NIX_DIR/aprs_tracker.ini $TRACKER_CFG_FILE
fi

echo
echo "== setup systemd service"

# Need to set a user in config file
CFG_USER=$(grep -i "user" $TRACKER_CFG_FILE | cut -d"=" -f2 | tr -d ' ')
if [ -z $CFG_USER ] ; then
   echo "user = $USER" | sudo tee -a $TRACKER_CFG_FILE
fi

# Need to set a CALLSIGN in config file
dbgecho "About to change MYCALL to $CALLSIGN"
sudo sed -i -e "/^mycall = N0CALL/ s/NOCALL/$CALLSIGN/" $TRACKER_CFG_FILE

# For DRAWS hat gps type needs to be gpsd
# look at 'type =' argument in [gps] section
gpstype=$(sudo sed -n '/\[gps\]/,/\[/p'  "$TRACKER_CFG_FILE" | grep -i "^type =" | cut -f3 -d' ')

#echo "gps type: $gpstype"
if [ "$gpstype" != "gpsd" ] ; then
    echo "gps type needs to be gpsd, currently: $gpstype"
    echo "comment all type lines in [gps] section"
    sudo sed -e '/\[gps\]/,/\[/s/^\(^type =.*\)/#\1/g'  "$TRACKER_CFG_FILE"
    echo "uncomment gpsd line"
    # reference: sed -i '/^#.* 2001 /s/^#//' file
    sudo sed -ie '/\[gps\]/,/\[/s/^#type = gpsd/type = gpsd/g' "$TRACKER_CFG_FILE"
else
    echo "gps type: $gpstype OK"
fi

# Need to set a lat/long
echo "Set static lat/lon TBD"

echo
echo "== setup systemd service"

# Check for an incompatible service entry installed with paclink-unix
SERVICE_NAME="pluweb.service"
if [ -f /etc/systemd/system/$SERVICE_NAME ] ; then
   echo "Replacing $SERVICE_NAME"
   sudo systemctl stop $SERVICE_NAME
   sudo systemctl disable $SERVICE_NAME
   sudo rm /etc/systemd/system/$SERVICE_NAME
fi

# Install all tracker systemd service files
program="${LOCAL_BIN_DIR}/tracker-ctrl.sh"
type -P $program >/dev/null 2>&1
if [ "$?"  -ne 0 ]; then
    echo "Require $program to install systemd service, but script could not be found"
fi

${LOCAL_BIN_DIR}/tracker-ctrl.sh -f

if [ 1 -eq 0 ] ; then
# ===== Problem
# == setup systemd service
# Replacing pluweb.service
# Removed /etc/systemd/system/multi-user.target.wants/pluweb.service.
# Created symlink /etc/systemd/system/multi-user.target.wants/tracker.service  /etc/systemd/system/tracker.service.
# A dependency job for tracker.service failed. See 'journalctl -xe' for details.

# Check if systemd service has already been installed
#SERVICE_NAMES="tracker.service"
SERVICE_NAMES="aprs-server tracker-webserver plu-webserver"
for service in `echo "${SERVICE_NAMES}"` ; do
    if [ ! -f /etc/systemd/system/$service ] ; then
        # $TRACKER_N7NIX_DIR/$SERVICE_NAME should be in $user file space
        sed -i -e "s/\$user/$USER/" $TRACKER_N7NIX_DIR/$service

        sudo cp $TRACKER_N7NIX_DIR/$service /etc/systemd/system/
        start_service $service
    else
        echo "System service $service already installed."
    fi
done

fi # comment out above code

sudo systemctl daemon-reload

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: ${tracker_type}tracker build & install script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
echo
