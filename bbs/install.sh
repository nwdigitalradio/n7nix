#!/bin/bash
#
# Install FBB BBS
#
BBS_VER="7.0.8-beta7"
num_cores=$(nproc --all)

SRC_DIR="/usr/local/src/"
scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
USER=

PKG_REQUIRE=""
PKG_REQUIRE_X11="libx11-dev ligxt-dev libxext-dev libxpm-dev lesstif2-dev"

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

   dbgecho "using USER: $USER"
}

# ===== main
echo -e "\n\tInstall FBB BBS\n"

# Running as root?
if [[ $EUID == 0 ]] ; then
   echo
   echo "Not required to run this script as root ...."
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

echo "=== Install fbb version $BBS_VER from source using $num_cores cores"

cd "$SRC_DIR"
sudo wget https://sourceforge.net/projects/linfbb/files/latest/download/fbb-$BBS_VER.tar.bz2
echo "wget ret: $?"
sudo tar xjvf fbb-$BBS_VER.tar.bz2
echo "wget ret: $?"
sudo chown -R $USER:$USER fbb-$BBS_VER/
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

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: fbb BBS install script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
echo

# (End of Script)
