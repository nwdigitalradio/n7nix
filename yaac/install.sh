#!/bin/bash
#
# Install APRS app yaac
#

SRC_DIR="/usr/local/src/"
YAAC_SRC_DIR=$SRC_DIR/yaac
YAAC_DST_DIR=$HOME/YAAC
scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
USER=

PKG_REQUIRE="openjdk-8-jre-headless openjdk-8-jre librxtx-java unzip xterm"

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

# ==== function install_zip
# Unzip yaac & create a desktop icon

function install_zip() {
    cd $YAAC_DST_DIR
    unzip -oq $YAAC_SRC_DIR/YAAC.zip
    echo "$(tput setaf 4)Finished yaac install, installing desktop icon$(tput setaf 7)"
    cd $START_DIR
    cp yaac.desktop /home/$USER/Desktop
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

START_DIR=$(pwd)

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
   echo -e "\t Installing Support libraries \t"

   sudo apt-get install -y -q $PKG_REQUIRE
   if [ "$?" -ne 0 ] ; then
      echo "$(tput setaf 1)apt-get install failed! Please try the following command manually:$(tput setaf 7)"
      echo "apt-get install -y $PKG_REQUIRE"
      exit 1
   fi
fi

echo "All required packages installed."

# Does source directory exist?

if [ ! -d $YAAC_SRC_DIR ] ; then
   sudo mkdir -p $YAAC_SRC_DIR
   if [ "$?" -ne 0 ] ; then
      echo "Problems creating source directory: $YAAC_SRC_DIR"
      exit 1
   fi
else
   echo "YAAC source directory: $YAAC_SRC_DIR already exists, will try to update"
fi

sudo chown -R $USER:$USER $YAAC_SRC_DIR
# Does destination directory exist?
if [ ! -d $YAAC_DST_DIR ] ; then
   sudo mkdir -p $YAAC_DST_DIR
   if [ "$?" -ne 0 ] ; then
      echo "Problems creating destination directory: $YAAC_DST_DIR"
      exit 1
   fi
else
   echo "YAAC destination directory: $YAAC_DST_DIR already exists, will try to update"
fi
sudo chown -R $USER:$USER $YAAC_DST_DIR

cd "$YAAC_SRC_DIR"

download_filename="YAAC.zip"
download_shaname="YAAC.sha256"
# Download sha file:
wget -r -O $download_shaname http://www.ka2ddo.org/ka2ddo/$download_shaname
if [ $? -ne 0 ] ; then
   echo "$(tput setaf 1)FAILED to download file: $download_shaname$(tput setaf 7)"
   gotsha256=0
# for now we keep going and bypass this error maybe more checking later
else
   gotsha256=1
fi

if [ $gotsha256 -ne 0 ] ; then
   shasum -c $download_shaname
   if [ $? -ne 0 ] ; then
     echo "$(tput setaf 1)shasum not exist or not ok renaming file  $(tput setaf 7)"
     if [ -e "$YAAC_SRC_DIR/$download_filename" ] ; then
        mv "$YAAC_SRC_DIR/$download_filename" "$YAAC_SRC_DIR/$download_filename".old
     fi
   else
     echo "$(tput setaf 1)shasum ok keep going $(tput setaf 7)"
   fi
fi
# Download zip file:
download_filename="YAAC.zip"
if [ ! -e "$YAAC_SRC_DIR/$download_filename" ] ; then
    wget http://www.ka2ddo.org/ka2ddo/$download_filename
    if [ $? -ne 0 ] ; then
        echo "$(tput setaf 1)FAILED to download file: $download_filename$(tput setaf 7)"
    else
        install_zip
    fi
else
    install_zip
fi

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: YAAC install script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
echo
