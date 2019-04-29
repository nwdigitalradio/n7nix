#!/bin/bash
#
# Install Updates for the Linux RMS Gateway
#
# 10/30/2014
# Parts taken from RMS-Upgrade-181 script
# (https://groups.yahoo.com/neo/groups/LinuxRMS/files)
# by C Schuman, K4GBB k4gbb1gmail.com
#
# 10/29/2018
# Changed to use git from this repo:
# github.com/nwdigitalradio/rmsgw
#
# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
REPO_BASE_DIR="$HOME/dev/github"
RMSGW_BUILD_DIR="$REPO_BASE_DIR/rmsgw"

PKG_REQUIRE="xutils-dev libxml2 libxml2-dev python-requests"
RMS_BUILD_FILE="rmsbuild.txt"

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

echo -e "$(tput setaf 6)\n \t  Install Linux RMS Gateway\n$(tput setaf 7)  Parts of this Script provided by Charles S. Schuman ( K4GBB )  \n"

# Running as root?
if [[ $EUID == 0 ]] ; then
   echo
   echo "Not required to run this script as root ...."
   exit 1
fi

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

# if there are any args on command line assume it's
# user name & callsign
if (( $# != 0 )) ; then
   USER="$1"
else
   get_user
fi

if [ -z "$USER" ] ; then
   echo "USER string is null, get_user"
   get_user
else
   echo "USER=$USER not null"
fi

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

if $needs_pkg ; then
   echo -e "$(tput setaf 6)\t Installing Support libraries \t$(tput setaf 7)"

   sudo apt-get install -y -q $PKG_REQUIRE
   if [ "$?" -ne 0 ] ; then
      echo "$(tput setaf 1)Support library install failed. Please try this command manually:$(tput setaf 7)"
      echo "apt-get install -y $PKG_REQUIRE"
      exit 1
   fi
fi

echo "All required packages installed."

#
# Use git to either get the rmsgw repo or update it.
#

# Find shortest path to rmsgw dir - not used
find "$HOME" -type d -name "rmsgw" -printf "%d %p\n" | sort -n | cut -d' ' -f2 | head -1

# go to repo dir $REPO_BASE_DIR

# Does repo directory exist?
if [ ! -d $REPO_BASE_DIR ] ; then
   mkdir -p $REPO_BASE_DIR
   if [ "$?" -ne 0 ] ; then
      echo "Problems creating repo directory: $REPO_BASE_DIR"
      exit 1
   fi
else
   echo "Repo directory: $REPO_BASE_DIR already exists, will try to update"
fi

# Does repo directory exist?
if [ ! -d "$RMSGW_BUILD_DIR" ] ; then
   # repo not there so clone it
   cd $REPO_BASE_DIR
   git clone https://github.com/nwdigitalradio/rmsgw
   if [ "$?" -ne 0 ] ; then
      echo "$(tput setaf 1)Problem cloning repository rmsgw$(tput setaf 7)"
      exit 1
   fi
   # Change permissions to USER for build
   sudo chown -R $USER:$USER $RMSGW_BUILD_DIR
else
   echo "Directory rmsgw already exists, attempting to update"
   cd $RMSGW_BUILD_DIR
   # Test if this diretory is really a git repo
   git rev-parse --is-inside-work-tree
   if [ "$?" -ne 0 ] ; then
      echo "$(tput setaf 1)Directory is not a git repo$(tput setaf 7)"
      echo "Change REPO_BASE_DIR variable at beginning of this script"
      exit 1
   fi

   git pull
   if [ "$?" -ne 0 ] ; then
      echo "$(tput setaf 1)Problem updating repository rmsgw$(tput setaf 7)"
      exit 1
   fi
fi

# Go to the build directory
cd $RMSGW_BUILD_DIR
echo -e "$(tput setaf 4)\t Build RMS Gateway source$(tput setaf 7)"
# Redirect stderr to stdout & capture to a file
make -j$num_cores > $RMS_BUILD_FILE 2>&1
if [ $? -ne 0 ] ; then
   echo -e "$(tput setaf 1)\tCompile error$(tput bold)$(tput setaf 7) - check $RMS_BUILD_FILE File \t$(tput sgr0)"
   exit 1
fi

echo -e "$(tput setaf 4)\t Installing RMS Gateway$(tput setaf 7)"
sudo make install
if [ $? -ne 0 ] ; then
  echo "$(tput setaf 1)Error during install.$(tput setaf 7)"
  exit 1
fi
# rm /etc/rmsgw/stat/.*

echo "$(date "+%Y %m %d %T %Z"): $scriptname: RMS Gateway updated" | sudo tee -a $UDR_INSTALL_LOGFILE
echo -e "$(tput setaf 4)RMS Gateway updated \t$(tput setaf 7)"

# (End of Script)
