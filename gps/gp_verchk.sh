#!/bin/bash
#
# Uncomment this statement for debug echos
#DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

UPDATE_FLAG=false
USER=
SRC_DIR="/usr/local/src"
SRC_DIR_GPSD="$SRC_DIR/gpsd-*"
BIN_DIR="/usr/local/bin"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# ===== Display program help info
#
usage () {
	(
	echo "Usage: $scriptname [-u][-l][-h]"
        echo "    No arguments displays current & installed versions."
        echo "    -u Set application update flag."
        echo "       Update source, build & install."
        echo "    -l display local version only."
        echo "    -h display this message."
        echo
	) 1>&2
	exit 1
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

# ===== function get_installed_version

function get_installed_version() {
    # Get installed version number of Xastir programs

    installed_prog_ver=

    # Get second string separated by a space
    # Also delete preceding cr & white space
    installed_prog_ver=$(gpsd -V | cut -d' ' -f2)
}

# ===== function get_source_version

function get_source_version() {
    # Get installed version number of Xastir programs

    source_prog_ver=
    cd "$SRC_DIR_GPSD"
    #./revision.h:#define REVISION "3.18.1"
    source_prog_ver=$(grep -i revision revision.h | cut -d' ' -f3 | tr -d '\"')
}

# ==== main

progname="gpsd"

# Check for any command line arguments
# Command line args are passed with a dash & single letter
#  See usage function

while [[ $# -gt 0 ]] ; do

    key="$1"
    case $key in
        -l)
            dbgecho "Display local version only."
            get_installed_version
            echo "$progname: $installed_prog_ver"
            exit
        ;;
        -u)
            echo "Update HF apps after checking version numbers."
            echo
            UPDATE_FLAG=true
        ;;
        -h)
            usage
            exit 0
        ;;
        *)
            echo "Undefined argument: $key"
            usage
            exit 1
        ;;
    esac
    shift # past argument or value
done

# Verify that gp_install program can be found
