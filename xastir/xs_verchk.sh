#!/bin/bash
#
# Uncomment this statement for debug echos
#DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

UPDATE_FLAG=false
USER=
SRC_DIR="/usr/local/src"
SRC_DIR_XASTIR="$SRC_DIR/Xastir"
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
    # Get installed version number of Xastir program

    installed_prog_ver=

    # Get second string separated by a space
    # Also delete preceding cr & white space
    # xastir only supported -V option after version 2.1.1
    prog_ver=$(xastir -V 2>&1 | cut -d' ' -f2)
    grep -i "invalid"  > /dev/null 2>&1 <<< "$prog_ver"
    if [ "$?" -eq 0 ] ; then
        installed_prog_ver="2.0.8?"
    else
        # Delete all white space
        prog_ver=$(echo $prog_ver | tr -d '[:space:]')

        # Remove leading 'V'
        installed_prog_ver="${prog_ver:1}"
    fi
}

# ===== function get_source_version

function get_source_version() {
    # Get latest source version number of Xastir program

    source_prog_ver=
    if [ ! -e "$SRC_DIR_XASTIR/configure.ac" ] ; then
        echo "Source not downloaded."
    else
        cd "$SRC_DIR_XASTIR"
        source_prog_ver=$(grep -i "AC_INIT(\[xastir\]," configure.ac | cut -d',' -f2 | tr -d '[:space:]' | tr -d '[]')
    fi
}

# ===== function test_xastir_ver
# Verify version displayed on command line is same as what was
# installed

function test_xastir_ver() {

    # Test if xastir was installed ok
    # Get version number of Xastir from command line
    get_installed_version
    get_source_version

    echo "Debug: Testing $source_prog_ver, ver: $installed_prog_ver"

    if [ "$source_prog_ver" != "$installed_prog_ver" ] ; then
        echo "$(tput setaf 1)Xastir version built ($installed_prog_ver) does not match source version ($source_prog_ver) $(tput setaf 7)"
    fi
}

# ===== function install_xastir

function install_xastir() {
retcode=1
if [ "$installed_prog_ver" != "$source_prog_ver" ] ; then
    if $UPDATE_FLAG ; then
        echo "      versions are different and WILL be updated."
        dbgecho "Sending command: ./xs_install.sh $USER"
        /bin/bash ./xs_install.sh "$USER"
        test_xastir_ver
        retcode=0
    fi
else
    echo "$progname: Running current version $installed_prog_ver"
fi
return $retcode
}

# ==== main

progname="xastir"

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
            dbgecho "Update Xastir after checking version number."
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

# Verify that xs_install.sh program can be found
# Need to run this script in the same directory as the
#   xastir/xs_install.sh script
if $UPDATE_FLAG ; then
    prog_name="./xs_install.sh"
    dbgecho "Update flag set, check for $progname"

    type -P $prog_name  >/dev/null 2>&1
    if [ "$?"  -ne 0 ]; then
        echo "Need $prog_name for Xastir program update but could not be found"
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

# Progname must be xastir
# Determine if xastir has ever been installed
dbgecho "Get installed version of Xastir"
type -P $progname >/dev/null 2>&1
if [ "$?"  -ne 0 ] ; then
    installed_prog_ver="NOT installed"
else
    get_installed_version
fi

# Find latest xastir source version
pushd $SRC_DIR > /dev/null

dbgecho "Get latest Xastir source: $(pwd)"

# Begin DO NOT Execute
if  [ 1 -eq 0 ] ; then
# Check Xastir source directory
if [ ! -d "$SRC_DIR_XASTIR" ] ; then
    # Xastir directory does NOT exist
    git clone https://github.com/Xastir/Xastir.git
else
    # Xastir source directory exists, verify it is a git repo & update
    # Test if this diretory is really a git repo
    cd "$SRC_DIR_XASTIR"
    # outputs either "true" or "false"
    git_tree=$(git rev-parse --is-inside-work-tree)
    if [ "$git_tree" != "true" ] ; then
        echo " Directory: $SRC_DIR_XASTIR is not a git repo"
        echo "Change SRC_DIR variable at beginning of this script"
        exit 1
    fi
    # Refresh repo
    git pull -q
    if [ "$?" -ne 0 ] ; then
        echo "Problem updating repository $PROG"
        exit 1
    fi
fi
fi
# end DO NOT Execute

dbgecho "Get Xastir source version"

get_source_version

popd > /dev/null

install_method="source"
is_pkg_installed $progname
if [ $? -ne 0 ] ; then
    dbgecho "$scriptname: No package found, $progname will be installed/updated from source"
else
    # Found xastir package, will uninstall
    echo "$scriptname: Detected $progname package."
fi

echo "$progname: current version: $source_prog_ver, installed: $installed_prog_ver"
if $UPDATE_FLAG ; then

    install_xastir
    # Only put a log entry if install script was called.
    if [ $? -eq 0 ] ; then
        echo
        echo "$(date "+%Y %m %d %T %Z"): $scriptname: Xastir program update script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
        echo
    fi
fi
