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
user=$(whoami)

SRC_DIR="/home/$user/dev"
BIN_DIR="/home/$user/bin"
BIN_DIR_1="/usr/local/bin"

# tracker type can be either dan or nix
# nixtracker adds Winlink ability
tracker_type="nix"
#tracker_type="dan"

TRACKER_DEST_DIR="$BIN_DIR"
TRACKER_DEST_DIR_1="$BIN_DIR_1"
TRACKER_CFG_DIR="/etc/tracker"
TRACKER_SRC_DIR="$SRC_DIR/${tracker_type}tracker"
TRACKER_N7NIX_DIR="/home/$user/n7nix/tracker"

LIBFAP_SRC_DIR="$SRC_DIR/libfap"
JSON_C_SRC_DIR="$SRC_DIR/json-c"
LIBFAP_VER="1.5"
LIBINIPARSER_VER="3.1"
NODEJS_VER="8.4.0"

SERVICE_NAME="tracker.service"
BIN_FILES="iptable-up.sh iptable-flush.sh iptable-check.sh tracker-up tracker-down tracker-restart .screenrc.trk"
#PKGLIST="hostapd dnsmasq iptables iptables-persistent"
PKGLIST="build-essential pkg-config imagemagick automake autoconf libtool libgps-dev iptables screen"

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
sudo apt-get -y install $PKGLIST

node_file_name="node-v$NODEJS_VER-linux-armv7l.tar.xz"

if [ ! -f $node_file_name ] ; then
   echo "Download node.js from nodejs.org"
   wget https://nodejs.org/dist/v$NODEJS_VER/$node_file_name
   current_dir=$(pwd)
   pushd /usr/local
   sudo tar --strip-components 1 -xvf $current_dir/$node_file_name
   echo "node version: $(/usr/local/bin/node -v)"
   echo "npm version: $(/usr/local/bin/npm -v)"
   echo
   echo "== get node modules"
   sudo npm -g install ctype iniparser websocket connect serve-static finalhandler uid-number
   cd
fi

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
   cd json-c

   sh autogen.sh
   ./configure
   make
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

if [ -d $TRACKER_DEST_DIR ] ; then
   mkdir -p $TRACKER_DEST_DIR
fi

echo
echo "== install ${tracker_type}tracker"

   cd $TRACKER_SRC_DIR
   cp scripts/* $TRACKER_DEST_DIR
   cp aprs  $TRACKER_DEST_DIR
   sudo cp aprs  $TRACKER_DEST_DIR_1
   rsync -av $TRACKER_SRC_DIR/webapp $TRACKER_DEST_DIR
   rsync -av $TRACKER_SRC_DIR/images $TRACKER_DEST_DIR/webapp
   if [ ! -d $TRACKER_DEST_DIR/webapp/jQuery ] ; then
      mkdir -p $TRACKER_DEST_DIR/webapp/jQuery
   fi
   cd $TRACKER_DEST_DIR/webapp/jQuery
   wget https://code.jquery.com/jquery-3.2.1.min.js
   mv jquery-3.2.1.min.js jquery.js

# This overwrites some of the ${tracker_type}tracker scripts from the n7nix repo
echo
echo "== setup bin dir"
for filename in `echo ${BIN_FILES}` ; do
   cp $TRACKER_N7NIX_DIR/$filename $BIN_DIR
done

sed -i -e "s/\$user/$user/" $BIN_DIR/tracker-up
sed -i -e "s/\$user/$user/" $BIN_DIR/tracker-restart

# Note: This should be in core_install.sh
#
# These rules block Bonjour/Multicast DNS (mDNS) addresses from iTunes
# or Avahi daemon.  Avahi is ZeroConf/Bonjour compatible and installed
# by default.
#
# Setup iptables then install iptables-persistent or manually update
# rules.v4

# Setup some iptable rules
echo
echo "== setup iptables"
sudo $BIN_DIR/iptable-up.sh

pkg_name="iptables-persistent"
is_pkg_installed $pkg_name
if [ $? -ne 0 ] ; then
   # installing iptables-persistent automatically saves current iptable
   # rules to /etc/iptables/rules.v4
   echo "$scriptname: Will Install $pkg_name program"
   sudo apt-get -y install iptables-persistent
else
   # Since iptables-peristent is already installed have to update
   # rules to /etc/iptables/rules.v4 manually
   sudo iptables-save > /etc/iptables/rules.v4
fi

if [ ! -d $TRACKER_CFG_DIR ] ; then
   sudo mkdir -p $TRACKER_CFG_DIR
fi

if [ -f $TRACKER_CFG_DIR/aprs_tracker.ini ] ; then
   echo "** tracker already config'ed in $TRACKER_CFG_DIR"
   echo "** please edit manually."
else
   sudo cp $TRACKER_N7NIX_DIR/aprs_tracker.ini $TRACKER_CFG_DIR
fi

sed -i -e "s/\$user/$user/" $TRACKER_N7NIX_DIR/$SERVICE_NAME
echo
echo "== setup systemd service"
sudo cp $TRACKER_N7NIX_DIR/$SERVICE_NAME /etc/systemd/system/
sudo systemctl enable $SERVICE_NAME
sudo systemctl daemon-reload
sudo systemctl start $SERVICE_NAME

echo
echo "finished building & installing ${tracker_type}tracker"
