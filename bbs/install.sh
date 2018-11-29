#!/bin/bash
#
# Install FBB BBS
#
BBS_VER="7.0.8-beta7"
num_cores=$(nproc --all)

PKG_REQUIRE=""
PKG_REQUIRE_X11="libx11-dev ligxt-dev libxext-dev libxpm-dev lesstif2-dev"

# ===== main
echo -e "\n\tInstall FBB BBS\n"

# Running as root?
if [[ $EUID == 0 ]] ; then
   echo
   echo "Not required to run this script as root ...."
   exit 1
fi

# check if required packages are installed
dbgecho "Check packages: $PKG_REQUIRE"

echo "=== Install fbb version $BBS_VER from source using $num_cores cores"
SRC_DIR="/usr/local/src/"
cd "$SRC_DIR"
wget https://sourceforge.net/projects/linfbb/files/latest/download/fbb-$BBS_VER.tar.bz2
echo "wget ret: $?"
tar xjvf fbb-$BBS_VER.tar.bz2
echo "wget ret: $?"
cd fbb-$BBS_VER/
./configure
echo "configure ret: $?"

make
echo "make ret: $?"

sudo make install
echo "make install ret: $?"

sudo make installconf
echo "make installconf ret: $?"

# Start bbs
# /usr/local/share/doc/fbb/fbb.sh start

# connect bbs
# xfbbC -c -h localhost -i n7nix

# Stop bbs
# kill $(pidof xfbbd)
