#!/bin/bash
#
# Install latest version of dantracker
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
TRACKER_DEST_DIR="$BIN_DIR"
TRACKER_CFG_DIR="/etc/tracker"
TRACKER_SRC_DIR="$SRC_DIR/dantracker"
TRACKER_N7NIX_DIR="/home/$user/n7nix/tracker"

LIBFAP_SRC_DIR="$SRC_DIR/libfap"
JSON_C_SRC_DIR="$SRC_DIR/json-c"
LIBFAP_VER="1.5"

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

# ===== main

# Don't be root
if [[ $EUID == 0 ]] ; then
   echo "Don't be root"
   exit 1
fi

pushd

if [ ! -d $SRC_DIR ] ; then
   mkdir -p $SRC_DIR
fi

# Need to get tracker source before building libfap
if [ -d $TRACKER_SRC_DIR ] ; then
   echo "** already have tracker source"
else
   echo
   echo "== get dantracker source"
   cd $SRC_DIR
   git clone https://github.com/n7nix/dantracker
fi

popd

# as root install a bunch of stuff
sudo apt-get -y install $PKGLIST

node_file_name="node-v8.4.0-linux-armv7l.tar.xz"

if [ ! -f $node_file_name ] ; then
   echo "Download node.js from nodejs.org"
   wget https://nodejs.org/dist/v8.4.0/$node_file_name
   current_dir=$(pwd)
   pushd /usr/local
   sudo tar --strip-components 1 -xvf $current_dir/$node_file_name
   echo "node version: $(/usr/local/bin/node -v)"
   echo "npm version: $(/usr/local/bin/npm -v)"
   echo
   echo "== get node modules"
   sudo npm -g install ctype iniparser websocket connect serve-static finalhandler
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
   wget http://ndevilla.free.fr/iniparser/iniparser-3.1.tar.gz
   tar -zxvf iniparser-3.1.tar.gz
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
   echo "== build dantracker"
   cd $TRACKER_SRC_DIR
   make
fi

if [ -d $TRACKER_DEST_DIR ] ; then
   mkdir -p $TRACKER_DEST_DIR
fi

echo
echo "== install dantracker"

   cd $TRACKER_SRC_DIR
   cp scripts/* $TRACKER_DEST_DIR
   cp aprs  $TRACKER_DEST_DIR
   rsync -av $TRACKER_SRC_DIR/webapp $TRACKER_DEST_DIR
   rsync -av $TRACKER_SRC_DIR/images $TRACKER_DEST_DIR/webapp
   if [ ! -d $TRACKER_DEST_DIR/webapp/jQuery ] ; then
      mkdir -p $TRACKER_DEST_DIR/webapp/jQuery
   fi
   cd $TRACKER_DEST_DIR/webapp/jQuery
   wget https://code.jquery.com/jquery-3.2.1.min.js
   mv jquery-3.2.1.min.js jquery.js


# This overwrites some of the dantracker scripts from the n7nix repo
echo
echo "== setup bin dir"
for filename in `echo ${BIN_FILES}` ; do
   cp $TRACKER_N7NIX_DIR/$filename $BIN_DIR
done

echo
echo "== setup systemd service"
cp $TRACKER_N7NIX_DIR/$SERVICE_NAME /etc/systemd/system/
systemctl enable $SERVICE_NAME
systemctl daemon-reload
systemctl start $SERVICE_NAME

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

if [ -f $TRACKER_CFG_DIR/aprs_tracker.ini ] ; then
   echo "** tracker already config'ed in $TRACKER_CFG_DIR"
   echo "** please edit manually."
else
   sudo cp $TRACKER_SRC_DIR/examples/aprs_tracker.ini $TRACKER_CFG_DIR
fi
echo
echo "finished building/installing dantracker"
