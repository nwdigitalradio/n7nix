#!/bin/bash
#
# Uncomment this statement for debug echos
#DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

UPDATE_FLAG=false
UPDATE_EXEC_FLAG=false
USER=

# For fl apps use this url
fl_url="http://www.w1hkj.com/files"


function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== Display program help info
#
usage () {
	(
	echo "Usage: $scriptname [-u][-l][-s][-h]"
        echo "    No arguments displays current & installed versions."
        echo "    -u Set application update flag."
        echo "       Update source, build & install."
        echo "    -l display local versions only."
        echo "    -s display available swap space."
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


# ===== function display_swap_size
# Just display swap file size

function display_swap_size() {
    swap_size_on=$(swapon -s | tail -n1 | expand -t 1 | tr -s '[[:space:]] ' | cut -d' ' -f3)
    swap_size_on_used=$(swapon -s | tail -n1 | expand -t 1 | tr -s '[[:space:]] ' | cut -d' ' -f4)
    if [ "$swap_size_on_used" -ne "0" ] ; then
        echo "Using swap space: $swap_size_on_used"
    else
        echo "All swap space available, none used."
    fi
    swap_size_free=$(free | tail -n1 | expand -t 1 | tr -s '[[:space:]] ' | cut -d' ' -f2)
    echo "swap size: $swap_size_on $swap_size_free"
}

# ===== function swap_size_check
# If swap too small, change config file /etc/dphys-swapfile & exit to
# do a reboot.
#
# To increase swap file size in /etc/dphys-swapfile:
# Default   CONF_SWAPSIZE=100    102396 KBytes
# Change to CONF_SWAPSIZE=1000  1023996 KBytes

function swap_size_check() {
    # Verify that swap size is large enough
    swap_size=$(swapon -s | tail -n1 | expand -t 1 | tr -s '[[:space:]] ' | cut -d' ' -f3)
    # Test if swap size is less than 1 Gig
    if (( swap_size < 1023996 )) ; then
        swap_config=$(grep -i conf_swapsize /etc/dphys-swapfile | cut -d"=" -f2)
        sudo sed -i -e "/CONF_SWAPSIZE/ s/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=1000/" /etc/dphys-swapfile

        echo "Swap size too small for builds, changed from $swap_config to 1000 ... need to reboot."
        exit 1
    fi
}


# ===== function fl_ver_get

# Get the version of a particular fl application
function fl_ver_get() {

    fl_app="$1"
    ver_url="$fl_url/$fl_app/"

    #curl -s "$ver_url" | grep -i ".tar.gz" | tail -n1 | cut -d '>' -f3 | cut -d '<' -f1
    fl_ver=$(curl -s "$ver_url" | grep -i ".tar.gz" | tail -1 | cut -d '>' -f3 | cut -d '<' -f1 | cut -d '-' -f2)
    fl_ver=$(basename $fl_ver .tar.gz)
}

# ===== function installed_prog_ver_get

# Get the installed version of an application
function installed_prog_ver_get() {
progname="$1"
SRC_DIR="/usr/local/src"

    type -P $progname >/dev/null 2>&1
    if [ "$?"  -ne 0 ]; then
        prog_ver="NOT installed"
    else
        if [ "${progname:0:2}" == "fl" ] ; then
            # Check for tarball
            dbgecho "Checking for tarball"
            if [ -e ${SRC_DIR/$progname}*.tar.gz ] ; then
                dbgecho "Get version from tarball: $progname"
                dirname="$(ls -1 $SRC_DIR/$progname*.tar.gz | tail -n1)"
                prog_ver=$(basename $dirname .tar.gz | cut -d '-' -f2)
            else
                dbgecho "Get version from directory name"
                # Get version number from directory name
                prog_ver=$(ls -d $SRC_DIR/$progname*/ | tail -n1 | cut -d'-' -f2 | tr -d '/')
#               prog_ver=$(grep -i version $SRC_DIR/$progname*/ChangeLog | head -n1)
           fi
        else
            #dirname="$(ls -1 $SRC_DIR/$progname*.deb | tail -n1)"
            #prog_ver=$(basename $dirname .deb | cut -d'_' -f2)
            prog_ver=$(dpkg -l $progname | tail -n 1 | tr -s ' ' | cut -d' ' -f3)
        fi
    fi
}

# ===== function installed_lib_ver_get
# Get the installed version of a library

function installed_lib_ver_get() {
progname="$1"
SRC_DIR="/usr/local/src"

    dbgecho "executing lib_ver_get for $progname"
    # Check if library loaded
    ldconfig -p | grep "lib$progname"  >/dev/null 2>&1
    if [ "$?" -ne 0 ] ; then
        echo "Library: lib$progname NOT loaded."
    else
        echo "Library: lib$progname IS loaded."
    fi

    # Check for source to build library
    ls "$SRC_DIR/$progname"* >/dev/null 2>&1
    if [ "$?" -ne 0 ]; then
        prog_ver="NOT installed"
    else
        if [ "${progname:0:3}" == "ham" ] || [ "${progname:0:4}" == "flxm" ] ; then
            # Check for tarball
            if [ -e $SRC_DIR/$progname*.tar.gz ] ; then
                dirname="$(ls -1 $SRC_DIR/$progname*.tar.gz)"
                prog_ver=$(basename $dirname .tar.gz | cut -d '-' -f2)
            else
                # Get version number from directory name
                prog_ver=$(ls -d $SRC_DIR/$progname* | cut -d'-' -f2)
#                dbgecho "Check change log in $progname directory"
#                grep version $SRC_DIR/$progname*/ChangeLog | head -n1 | cut -d' ' -f2
            fi
        else
            dirname="$(ls -1 $SRC_DIR/$progname*.deb)"
            prog_ver=$(basename $dirname .deb | cut -d'_' -f2)
        fi
    fi
}

# ===== function test_fldigi_ver
# Verify version displayed on command line is same as what was
# installed

function test_fldigi_ver() {
    flapp=$1
    flver=$2
#    echo "Debug: Testing $flapp, ver: $flver"
    # Test if fldigi was installed ok
    if [ "$flapp" == "fldigi" ] ; then
        # Get version number of fldigi from command line
        cl_ver=$(fldigi --version | head -n 1 | cut -d' ' -f2)
        if [ "$flver" != "$cl_ver" ] ; then
            echo "$(tput setaf 1)$flapp version built ($cl_ver) does not match source version ($flver) $(tput setaf 7)"
        fi
    fi
}

# ===== function installed_version_display

function installed_version_display() {
    # Get version numbers of all hf programs

    for progname in "js8call" "wsjtx" "fldigi" "flrig" "flmsg" "flamp" ; do
        installed_prog_ver_get "$progname"
        echo "$progname: $prog_ver"
        test_fldigi_ver "$progname" "$prog_ver"
    done
    # Check if hamlib has been loaded
    for libname in "hamlib" "flxmlrpc" ; do
        installed_lib_ver_get "$libname"
        echo "$libname: $prog_ver"
    done
}

# ==== main

# Check for any command line arguments
# Command line args are passed with a dash & single letter
#  See usage function

while [[ $# -gt 0 ]] ; do

    key="$1"
    case $key in
        -l)
            dbgecho "Display local versions only."
            installed_version_display
            exit
        ;;

        -s)
            echo "Display swap space used."
            display_swap_size
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

# Verify that hf_install program can be found
# Need to run this script in the same directory as the
#   hfprogs/hf_install.sh script
if $UPDATE_FLAG ; then
    progname="./hf_install.sh"
    dbgecho "Check for $progname"

    type -P $progname  >/dev/null 2>&1
    if [ "$?"  -ne 0 ]; then
        echo "Need $progname for HF program update but could not be found"
        exit 1
    else
        dbgecho "Found $progname"
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

# js8call
if [ -z "$DEBUG1" ] ; then
js8_app="js8call"
#ver_url="https://groups.io/g/js8call/wiki/Download-Links"
#curl  "$ver_url" | grep -A3 -i "RaspberryPi"
#curl "https://groups.io/g/js8call/wiki/Download-Links"

ver_url="https://bitbucket.org/widefido/$js8_app/downloads/?tab=tags"
js8_ver=$(curl -s $ver_url | grep -A1 -i "iterable-item" | head -2 | tail -1 | cut -d'>' -f2 | cut -d '<' -f1)
# Get rid of the leading v in string
js8_ver="${js8_ver:1}"

# Need to fix: js8call_1.0.1-ga_armhf.deb
# Get rid of the trailing -ga
js8_ver=$(echo $js8_ver | cut -d'-' -f1)

installed_prog_ver_get "$js8_app"
echo "$js8_app: current version: $js8_ver, installed: $prog_ver"
if $UPDATE_FLAG ; then
    if [[ "$js8_ver" != "$prog_ver" ]] ; then
        echo "         versions are different and WILL be updated."
        /bin/bash ./hf_install.sh "$USER" js8call "$js8_ver"
        UPDATE_EXEC_FLAG=true
    else
        echo "         version is current"
    fi
fi

fi

# wsjtx
if [ -z "$DEBUG1" ] ; then
wsjtx_app="wsjtx"
ver_url="http://physics.princeton.edu/pulsar/K1JT/$wsjtx_app.html"
wsjtx_ver=$(curl -s $ver_url | grep -i "Availability (GA)" | cut -d '>' -f3 | cut -d '<' -f1)
# curl -s $ver_url | grep -i "Availability (GA)" | cut -d '>' -f3 | cut -d '<' -f1
# Remove preceding white space
wsjtx_ver=$(echo ${wsjtx_ver##+([[:space:]])})

installed_prog_ver_get "$wsjtx_app"
echo "$wsjtx_app:   current version: $wsjtx_ver, installed: $prog_ver"
if $UPDATE_FLAG ; then
    if [[ "$wsjtx_ver" != "$prog_ver" ]] ; then
        echo "       versions are different and WILL be updated."
        /bin/bash ./hf_install.sh "$USER" wsjtx "$wsjtx_ver"
        UPDATE_EXEC_FLAG=true
    else
        echo "         version is current"
    fi
fi

fi

# Update all the fl programs
for fl_app in "flxmlrpc" "fldigi" "flrig" "flmsg" "flamp" ; do

    fl_ver_get "$fl_app"

    if [ "${fl_app:0:3}" == "ham" ] || [ "${fl_app:0:4}" == "flxm" ] ; then
        installed_lib_ver_get "$fl_app"
    else
        installed_prog_ver_get "$fl_app"
    fi
    echo "$fl_app:  current version: $fl_ver, installed: $prog_ver"
    test_fldigi_ver "$fl_app" "$prog_ver"

    if $UPDATE_FLAG ; then
        if [[ "$fl_ver" != "$prog_ver" ]] ; then
            # Only check swap file size for making fldigi
            if [ "$fl_app" = "fldigi" ] ; then
                swap_size_check
            fi
            echo "      versions are different and WILL be updated."
            dbgecho "Sending command: ./hf_install.sh $USER $fl_app $fl_ver"
            /bin/bash ./hf_install.sh "$USER" "$fl_app" "$fl_ver"
            UPDATE_EXEC_FLAG=true
            test_fldigi_ver "$fl_app" "$fl_ver"
        else
            echo "        version is current"
        fi
    fi
done

if $UPDATE_FLAG && $UPDATE_EXEC_FLAG ; then
    # Only put a log entry if install script was called
    echo
    echo "$(date "+%Y %m %d %T %Z"): $scriptname: hf program update script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
    echo
fi
