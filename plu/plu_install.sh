#!/bin/bash
#
# Install paclink-unix from source tree
#

# Uncomment this statement for debug echos
DEBUG=1
#DEFER_BUILD=1

myname="`basename $0`"
SRC_DIR="/usr/local/src"
PLU_CFG_FILE="/usr/local/etc/wl2k.conf"
PLU_VAR_DIR="/usr/local/var/wl2k"

BUILD_PKG_REQUIRE="build-essential autoconf automake libtool"
INSTALL_PKG_REQUIRE="postfix mutt libdb-dev libglib2.0-0 zlib1g-dev libncurses5-dev libdb5.3-dev libgmime-2.6-dev"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed")
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
  read USER
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

echo "paclink-unix install/config script"

# make sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root"
   exit 1
fi
# Save current directory
CUR_DIR=$(pwd)

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

   debconf-set-selections <<< "postfix postfix/mailname string $(hostname).localhost"
   debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

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
apt-get install postfix libdb-dev libglib2.0-0 zlib1g-dev libncurses5-dev libdb5.3-dev libgmime-2.6-dev

cd $SRC_DIR

if [ -d paclink-unix ] && (($(ls -1 paclink-unix | wc -l) > 56)) ; then
   echo "=== paclink-unix source already downloaded"
else
   echo "=== getting paclink-unix source"
   git clone https://github.com/nwdigitalradio/paclink-unix
   pwd
   rm -f paclink-unix/missing paclink-unix/test-driver
fi

## For Debugging check conditional for building paclink-unix
if [ -z "$DEFER_BUILD" ] ; then
   echo "=== building paclink-unix"
   echo "This will take a few minutes, output is captured to build_log.out"

   pushd paclink-unix

   cp README.md README
   echo "=== running autotools"
   aclocal > build_log.out 2> build_error.out
   if [ "$?" -ne 0 ] ; then echo "build failed at aclocal"; exit 1; fi
   autoheader >> build_log.out 2>> build_error.out
   if [ "$?" -ne 0 ] ; then echo "build failed at autoheader"; exit 1; fi
   automake --add-missing >> build_log.out 2>> build_error.out
   if [ "$?" -ne 0 ] ; then echo "build failed at automake"; exit 1; fi
   autoreconf >> build_log.out 2>> build_error.out
   echo "=== running configure"
   ./configure --enable-postfix >> build_log.out 2>> build_error.out
   if [ "$?" -ne 0 ] ; then echo "build failed at configure"; exit 1; fi
   echo "=== making paclink-unix"
   make >> build_log.out 2>> build_error.out
   if [ "$?" -ne 0 ] ; then echo "build failed at make"; exit 1; fi
   echo "=== installing paclink-unix"
   make install >> build_log.out 2>> build_error.out
   if [ "$?" -ne 0 ] ; then echo "build failed at make install"; exit 1; fi

   popd
fi

echo "=== test files 'missing' & 'test-driver'"
pwd
ls -salt $SRC_DIR/paclink-unix/missing $SRC_DIR/paclink-unix/test-driver

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

# set permissions for /usr/local/var/wl2k directory
# Check user name
get_user
chown -R $USER:mail $PLU_VAR_DIR

# Add user to group mail
if id -nG "$USER" | grep -qw mail; then
    echo "$USER already belongs to group mail"
else
    echo "Adding $USER to group mail"
    usermod -a -G mail $USER
fi

# Get callsign
echo "Enter call sign, followed by [enter]:"
read CALLSIGN

sizecallstr=${#CALLSIGN}

if (( sizecallstr > 6 )) || ((sizecallstr < 3 )) ; then
   echo "Invalid call sign: $CALLSIGN, length = $sizecallstr"
   exit 1
fi

# Convert callsign to upper case
CALLSIGN=$(echo "$CALLSIGN" | tr '[a-z]' '[A-Z]')

# Edit /usr/local/etc/wl2k.conf file
# sed -i  save result to input file

# Set mycall=
sed -i -e "/mycall=/ s/mycall=.*/mycall=$CALLSIGN/" $PLU_CFG_FILE

## Set email=user_name@localhost

sed -i -e "s/^#email=.*/email=$USER@localhost/" $PLU_CFG_FILE

# Set wl2k-password=
echo "Enter Winlink password, followed by [enter]:"
read PASSWD
sed -i -e "s/^#wl2k-password=/wl2k-password=$PASSWD/" $PLU_CFG_FILE

# Set ax25port=
# Assume axports was set by a previous configuration script
# get first arg in last line
PORT=$(tail -1 /etc/ax25/axports | cut -d ' ' -f 1)
sed -i -e "s/^#ax25port=/ax25port=$PORT/" $PLU_CFG_FILE

echo "paclink-unix install & config FINISHED"

# configure postfix
source $CUR_DIR/postfix_install.sh $USER
# configure mutt
source $CUR_DIR/mutt_install.sh $USER $CALLSIGN
