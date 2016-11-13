#!/bin/bash
#
# Install paclink-unix from source tree
#

# Uncomment this statement for debug echos
DEBUG=1

myname="`basename $0`"
SRC_DIR="/usr/local/src/"

BUILD_PKG_REQUIRE="build-essential autoconf automake libtool"
INSTALL_PKG_REQUIRE="postfix mutt libdb-dev libglib2.0-0 zlib1g-dev libncurses5-dev libdb5.3-dev libgmime-2.6-dev"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed")
}

# ===== main

# make sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root"
   exit 1
fi

# check if build packages are installed
dbgecho "Check build packages: $BUILD_PKG_REQUIRE"
needs_pkg=false

for pkg_name in `echo ${BUILD_PKG_REQUIRE}` ; do

   is_pkg_installed $pkg_name
   if [ $? -eq 0 ] ; then
      echo "$myname: Will Install $pkg_name package"
      needs_pkg=true
      break
   fi
done

if [ "$needs_pkg" = "true" ] ; then
   echo
   echo -e "=== Installing build tools"

   apt-get install -y -q $BUILD_PKG_REQUIRE
   if [ "$?" -ne 0 ] ; then
      echo "Build tool install failed. Please try this command manually:"
      echo "apt-get -y $BUILD_PKG_REQUIRE"
      exit 1
   fi
fi

# check if other required packages are installed
dbgecho "Check required packages: $INSTALL_PKG_REQUIRE"
needs_pkg=false

for pkg_name in `echo ${INSTALL_PKG_REQUIRE}` ; do

   is_pkg_installed $pkg_name
   if [ $? -eq 0 ] ; then
      echo "$myname: Will Install $pkg_name package"
      needs_pkg=true
      break
   fi
done

if [ "$needs_pkg" = "true" ] ; then
   echo
   echo -e "=== Installing required packages"

   apt-get install -y -q $INSTALL_PKG_REQUIRE
   if [ "$?" -ne 0 ] ; then
      echo "Required package install failed. Please try this command manually:"
      echo "apt-get -y $INSTALL_PKG_REQUIRE"
      exit 1
   fi
fi

# Does source directory exist?
if [ ! -d $SRC_DIR ] ; then
   mkdir -p $SRC_DIR
   if [ "$?" -ne 0 ] ; then
      echo "Problems creating source directory: $SRC_DIR"
      exit 1
   fi
fi

cd $SRC_DIR

if [ -f paclink-unix ] && (($(ls -1 paclink-unix | wc -l) > 56)) ; then
echo "=== getting paclink-unix source"
git clone https://github.com/nwdigitalradio/paclink-unix
fi

echo "=== building paclink-unix"
ls -l /usr/share/automake*
cd paclink-unix
cp /usr/share/automake-1.14/missing .
automake --add-missing
./autogen.sh --enable-postfix
make

echo "=== installing paclink-unix"
make install

echo "=== verifying paclink-unix install"
REQUIRED_PRGMS="wl2ktelnet wl2kax25 wl2kserial"
echo "Check for required files ..."
EXITFLAG=false

for prog_name in `echo ${REQUIRED_PRGMS}` ; do
   type -P $prog_name &>/dev/null
   if [ $? -ne 0 ] ; then
      echo "$myname: paclink-unix not installed properly"
      echo "$myname: Need to Install $prog_name program"
      EXITFLAG=true
   fi
done
if [ "$EXITFLAG" = "true" ] ; then
  exit 1
fi

echo "=== configuring paclink-unix"
