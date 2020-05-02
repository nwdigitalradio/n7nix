#!/bin/bash
#
# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
pkgname="direwolf"

#DW_VER="1.5"
DW_VER="dev"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {
dbgecho "Checking package: $1"
return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# ===== function install direwolf from source

function install_direwolf_source() {
   num_cores=$(nproc --all)
   echo "=== Install direwolf version $DW_VER from source using $num_cores cores"
   SRC_DIR="/usr/local/src/"
   cd "$SRC_DIR"
# This gets current HOT version
#   git clone https://www.github.com/wb2osz/direwolf
#   cd direwolf

   # This gets version $DW_VER
   wget https://github.com/wb2osz/direwolf/archive/$DW_VER.zip
   unzip $DW_VER.zip
   cd direwolf-$DW_VER

   echo "Building direwolf in directory $(pwd)"
   echo "As of Jan 6 (May 2) build will fail with \"
   /usr/local/src/direwolf-dev/src/dwgpsd.c:65:2: error: #error libgps API version might be incompatible."
   echo "See direwolf github issues #241"
   echo

   mkdir build && cd build
   cmake ..
   make -j$num_cores
   make install

   # NOTE: do not run make install-conf as that will wipe out your
   # previous config

   # Build from source puts executable in /usr/local/bin
   # Copy executable here to not have to edit sysd/direwolf.service file
   cp /usr/local/bin/direwolf /usr/bin
}

# ===== main

echo
echo "direwolf upgrade START"

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "$scriptname: Must be root."
   exit 1
fi

# First qualify an existing running direwolf

# Check version of direwolf installed
type -P direwolf &>/dev/null
if [ $? -ne 0 ] ; then
   echo "$scriptname: No direwolf program found in path"
   exit 1
else
   dire_ver=$(direwolf -v 2>/dev/null | grep -m 1 -i version | cut -d " " -f4)
   echo "Found direwolf version: $dire_ver"
fi

# Check if config file exists
if [ -f "/etc/direwolf.conf" ] ; then
   echo "Verified existing direwolf config file"
else
   echo "$scriptname: Direwolf config file: /etc/direwolf.conf DOES NOT EXIST, not upgrading"
   exit 1
fi

# Is direwolf package already installed?
is_pkg_installed "$pkgname"
if [ $? -ne 0 ] ; then
   echo "$pkgname NOT installed from a package"
else
   echo "$pkgname is already installed from a package, uninstalling."
   echo "Uninstalling $pkgname package"
   apt-get -y -q remove direwolf
fi

# Has direwolf source already been installed?
SRCDIR=
for DIR in "$(ls -d /usr/local/src/* | grep -i direwolf)" ; do
   if [ -d "$DIR" ] ; then
      SRCDIR=$DIR
      # Check if this is the same version intended to install
      if [[ "$SRCDIR" =~ "direwolf-$DW_VER" ]] ; then

        break
      fi
   fi
done

# check if SRCDIR var is set
if [ -d "$SRCDIR" ] ; then

   echo "Found an existing direwolf source directory: $SRCDIR"
   if [[ "$SRCDIR" =~ "direwolf-$DW_VER" ]] ; then
      echo "Renaming existing source directory"
      mv "$SRCDIR" "$SRCDIR.bak"
   else
      echo "Failed? $SRCDIR : direwolf-$DW_VER"
   fi
else
   echo "No previous direwolf source directory found"
fi

# Won't work if direwolf is still running
pid=$(pidof direwolf)
if [ $? -eq 0 ] ; then
   echo "Direwolf is running, with a pid of $pid, stopping direwolf."
   kill -9 $pid
else
   echo "Direwolf is not running, good!"
fi

install_direwolf_source

dire_new_ver=$(direwolf -v 2>/dev/null | grep -m 1 -i version)

echo "$(date "+%Y %m %d %T %Z"): $scriptname: direwolf update script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "direwolf version was: $dire_ver is now: $dire_new_ver"
echo
exit 0
