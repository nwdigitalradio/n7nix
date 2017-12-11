#!/bin/bash
#
# Depends on imap server,
#  - alpine can not read Maildir mail files.
#
# Uncomment this statement for debug echos
DEBUG=1
scriptname="`basename $0`"

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

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
   dbgecho " "
   dbgecho "using USER: $USER"
   dbgecho " "
}

# ===== main

echo "alpine mail client install script"

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root"
   exit 1
fi

# get dependencies: pam-dev package

pkg_name="libpam0g-dev"

is_pkg_installed $pkg_name
if [ $? -ne 0 ] ; then
   echo "$scriptname: Will Install $pkg_name program"
   apt-get install libpam0g-dev
fi

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"
get_user
check_user

SRC_DIR="/home/$USER/dev"

# Does source directory exist?
if [ ! -d "$SRC_DIR" ] ; then
   mkdir -p "$SRC_DIR"
   if [ $? -ne 0 ] ; then
      echo "Problems creating source directory: $SRC_DIR"
      exit 1
   fi
else
   dbgecho "Source dir: $SRC_DIR already exists"
fi

pushd $SRC_DIR

echo
echo "**** Check for alpine source"
echo

# Does source directory for alpine exist?
if [ ! -d "$SRC_DIR/alpine" ] ; then
   # get current alpine source
   git clone git://repo.or.cz/alpine.git
else
   dbgecho "Source dir for alpine: $SRC_DIR/alpine already exists"
fi

# build from source
# May have to run autoconf
cd alpine/
autoconf
./configure --with-ssl-include-dir=/usr/include/openssl --with-ssl-lib-dir=/usr/lib/arm-linux/gnueabihf/libssl.a --with-passfile=.pine-passfile
echo
echo "**** Building alpine"
echo
make -j4
echo
echo "**** Installing alpine"
echo
make install
popd
echo
echo "**** Alpine version:"
# Display version
alpine -v

# Configure alpine

# personal_name=

# user-domain=winlink.org

# customized-hdrs=From: n7nix,
#         Reply-To: N7NIX@winlink.org

# inbox-path={10.0.42.95/novalidate-cert/imap/SSL/user=pi}