#!/bin/bash
#
# Uncomment this statement for debug echos
#DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

UPDATE_FLAG=false
USER=
SRC_DIR="/usr/local/src"
SRC_DIR_GPSD="$SRC_DIR/gpsd"
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
    # Get installed version number of gpsd program

    installed_prog_ver=

    # Get second string separated by a space
    # Also delete preceding cr & white space
    installed_prog_ver=$(gpsd -V | cut -d' ' -f2)
}

# ===== function get_source_version

function get_source_version() {
    # Get source version number of gpsd program

    source_prog_ver=
    # cd "$SRC_DIR_GPSD"
    #./revision.h:#define REVISION "3.18.1"
    # source_prog_ver=$(grep -i revision revision.h | cut -d' ' -f3 | tr -d '\"')
    source_prog_ver=$(curl -s http://download-mirror.savannah.gnu.org/releases/gpsd/?C=M | tail -n 2 | head -n 1 | cut -d'-' -f2 | cut -d '.' -f1,2,3)
}

# ===== function test_gpsd_ver
# Verify version displayed on command line is same as what was
# installed

function test_gpsd_ver() {

    # Test if gpsd was installed ok
    # Get version number of gpsd from command line
    get_installed_version
    get_source_version

    echo "Debug: Testing $source_prog_ver, ver: $installed_prog_ver"

    if [ "$source_prog_ver" != "$installed_prog_ver" ] ; then
        echo "$(tput setaf 1)gpsd version built ($installed_prog_ver) does not match source version ($source_prog_ver) $(tput setaf 7)"
    fi
}

# ===== function install_gpsd

function install_gpsd() {
retcode=1
if [ "$installed_prog_ver" != "$source_prog_ver" ] ; then
    if $UPDATE_FLAG ; then
        echo "      versions are different and WILL be updated."
        dbgecho "Sending command: ./xs_install.sh $USER"
        /bin/bash ./gp_install.sh "$USER"
        test_gpsd_ver
        retcode=0
    fi
else
    echo "$progname: Running current version $installed_prog_ver"
fi
return $retcode
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
            dbgecho "Update gpsd after checking version numbers."
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

# Verify that gp_install.sh program can be found
if $UPDATE_FLAG ; then
    prog_name="./gp_install.sh"
    dbgecho "Update flag set, check for $progname"

    type -P $prog_name  >/dev/null 2>&1
    if [ "$?"  -ne 0 ]; then
        echo "Need $prog_name for gpsd program update but could not be found"
        exit 1
    else
        dbgecho "Found $prog_name"
    fi
    # Verify user name
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
fi

# Progname must be gpsd
# Determine if gpsd has ever been installed
dbgecho "Get installed version of gpsd"
type -P $progname >/dev/null 2>&1
if [ "$?"  -ne 0 ] ; then
    installed_prog_ver="NOT installed"
else
    get_installed_version
fi

# Find latest gpsd source version
pushd $SRC_DIR > /dev/null
dbgecho "Get latest gpsd source, pwd: $(pwd)"

get_source_version

popd > /dev/null

install_method="source"
is_pkg_installed $progname
if [ $? -ne 0 ] ; then
    dbgecho "$scriptname: No package found, $progname will be installed/updated from source"
else
    # Found gpsd package, will uninstall
    echo "$scriptname: Detected $progname package."
fi

if $UPDATE_FLAG ; then

    install_gpsd
    # Only put a log entry if install script was called.
    if [ $? -eq 0 ] ; then
        echo
        echo "$(date "+%Y %m %d %T %Z"): $scriptname: gpsd program update script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
        echo
    fi
else
    echo "$progname: current version: $source_prog_ver, installed: $installed_prog_ver"
fi
