#!/bin/bash
#
# Install paclink-unix from source tree
# Also installs mutt & postfix
#
# Uncomment this statement for debug echos
DEBUG=1
#DEFER_BUILD=1
USER=

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

SRC_DIR="/usr/local/src"
PLU_CFG_FILE="/usr/local/etc/wl2k.conf"
POSTFIX_CFG_FILE="/etc/postfix/transport"
PLU_VAR_DIR="/usr/local/var/wl2k"

BUILD_PKG_REQUIRE="build-essential autoconf automake libtool"
INSTALL_PKG_REQUIRE="postfix mutt libdb-dev libglib2.0-0 zlib1g-dev libncurses5-dev libdb5.3-dev libgmime-2.6-dev jq curl"

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

# ===== function files_exist()
function files_exist() {
   retcode=1

   for filename in `echo ${CFG_FILES}` ; do
      if [ ! -f "$filename" ] ; then
         retcode=0
      else
         echo "File check found: $filename"
      fi
   done
   return $retcode
}

# ===== main

echo
echo "paclink-unix install START"

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
   if [ $? -ne 0 ] ; then
      echo "$scriptname: Will Install $pkg_name package"
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
   if [ $? -ne 0 ] ; then
      echo "$scriptname: Will Install $pkg_name package"
      needs_pkg=true
      break
   fi
done

# Get user name, $USER
get_user
MUTT_CFG_FILE="/home/$USER/.muttrc"
CFG_FILES="$PLU_CFG_FILE $MUTT_CFG_FILE $POSTFIX_CFG_FILE"

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
else
   # Does NOT need any package
   # Have paclink-unix, mutt & postfix already been installed?
   files_exist
   if [ $? -eq 1 ] ; then
      echo "paclink-unix, mutt & postfix already installed ..."
      exit 0
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
   echo "This will take a few minutes, output is captured to $(pwd)/paclink-unix/build_log.out"

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
   num_cores=$(nproc --all)
   echo "=== making paclink-unix using $num_cores cores"
   make -j$num_cores >> build_log.out 2>> build_error.out
   if [ "$?" -ne 0 ] ; then echo "build failed at make"; exit 1; fi
   echo "=== installing paclink-unix"
   make install >> build_log.out 2>> build_error.out
   if [ "$?" -ne 0 ] ; then echo "build failed at make install"; exit 1; fi

   popd > /dev/null
fi

# Check that source dir belongs to user to that they can do a git pull
#  if required.
echo "=== test owner & group id of source directory"
if [ $(stat -c "%U" $SRC_DIR/paclink-unix) != "$USER" || $(stat -c "%G" $SRC_DIR/paclink-unix) != "$USER" ] ; then
   chown -R $USER:$USER $SRC_DIR/paclink-unix
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
      echo "$scriptname: paclink-unix not installed properly"
      echo "$scriptname: Need to Install $prog_name program"
      EXITFLAG=true
   fi
done
if [ "$EXITFLAG" = "true" ] ; then
  exit 1
fi

echo "$(date "+%Y %m %d %T %Z"): $scriptname: paclink-unix basic install script FINISHED" | tee -a $UDR_INSTALL_LOGFILE
echo
echo "paclink-unix install FINISHED"
echo
# install postfix
# Test if postfix package has already been installed.
pkg_name="postfix"
is_pkg_installed $pkg_name
if [ $? -ne 0 ] ; then
   echo "$scriptname: Will Install $pkg_name package"
   apt-get install -y -q $pkg_name
   echo "$(date "+%Y %m %d %T %Z"): $scriptname: postfix install script FINISHED" | tee -a $UDR_INSTALL_LOGFILE
fi

source $CUR_DIR/postfix_install.sh
# install mutt
source $CUR_DIR/../email/mutt/mutt_install.sh $USER $CALLSIGN
