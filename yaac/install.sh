#!/bin/bash
#
# Install APRS app yaac
#

SRC_DIR="/usr/local/src/"
YAAC_SRC_DIR=$SRC_DIR/yaac
scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
USER=

PKG_REQUIRE="openjdk-8-jre librxtx-java unzip"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

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

   dbgecho "using USER: $USER"
}

#
# ===== main
#

# Running as root?
if [[ $EUID == 0 ]] ; then
   echo
   echo "Not required to run this script as root ...."
   exit 1
fi

# Check if there are any args on command line
if (( $# != 0 )) ; then
    USER="$1"
else
    echo "$scriptname: Must supply user name as command line argument"
    exit 1
fi
# Check for any arguments
if (( $# != 0 )) ; then
   USER="$1"
fi

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

# Check if user name was supplied on command line
if [ -z "$USER" ] ; then
    # prompt for call sign & user name
    # Check if there is only a single user on this system
    get_user
fi

# Verify user name
check_user

# check if required packages are installed
dbgecho "Check packages: $PKG_REQUIRE"
needs_pkg=false

for pkg_name in `echo ${PKG_REQUIRE}` ; do

   is_pkg_installed $pkg_name
   if [ $? -ne 0 ] ; then
      echo "$scriptname: Will Install $pkg_name program"
      needs_pkg=true
      break
   fi
done

if [ "$needs_pkg" = "true" ] ; then
   echo -e "${BluW}\t Installing Support libraries \t${Reset}"

   sudo apt-get install -y -q $PKG_REQUIRE
   if [ "$?" -ne 0 ] ; then
      echo "$(tput setaf 1)Support library install failed. Please try this command manually:$(tput setaf 7)"
      echo "apt-get install -y $PKG_REQUIRE"
      exit 1
   fi
fi

echo "All required packages installed."

# Does source directory exist?

if [ if [ ! -d $YAAC_SRC_DIR ] ; then
   sudo mkdir -p $YAAC_SRC_DIR
   if [ "$?" -ne 0 ] ; then
      echo "Problems creating source directory: $YAAC_SRC_DIR"
      exit 1
   fi
else
   echo "YAAC source directory: $YAAC_SRC_DIR already exists, will try to update"
fi

sudo chown -R $USER:$USER $YAAC_SRC_DIR

cd "$YAAC_SRC_DIR"

# Download zip file:

wget http://www.ka2ddo.org/ka2ddo/YAAC.zip
if [ $? -ne 0 ] ; then
   echo "FAILED to download YAAC zip file."
   exit 1
fi

unzip YAAC.zip