#!/bin/bash
#
#  tt_install.sh
#
# - Install scripts to local bin
# - Modify direwolf config to enable Touch Tone commands
# This script has NO command line options.
#
# Uncomment this statement for debug echos
# DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
DIREWOLF_CFGFILE="/etc/direwolf.conf"

# Get latest version of WiringPi
CURRENT_WP_VER="2.60"
SRCDIR=/usr/local/src

# List of required programs
PROGLIST="sox at"

# ===== function dbgecho

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

function copy_local_bin() {

    src_dir="$1"
    # Check if local bin directory exists.
    if [ ! -d "$userbindir" ] ; then
        mkdir $userbindir
    fi

    cp -u $src_dir/speed_switch.sh $userbindir
    cp -u $src_dir/dw-ttcmd.sh $userbindir
    cp -u $src_dir/send-ttcmd.sh $userbindir
}

# ===== function get_wp_ver
# Get current version of WiringPi
function get_wp_ver() {
    wp_ver=$(gpio -v | grep -i "version" | cut -d':' -f2)

    # echo "DEBUG: $wp_ver"
    # Strip leading white space
    # This also works
    # wp_ver=$(echo $wp_ver | tr -s '[[:space:]]')"

    wp_ver="${wp_ver#"${wp_ver%%[![:space:]]*}"}"
}

# ===== function chk_wp_ver
# Check that the latest version of WiringPi is installed
function chk_wp_ver() {
    get_wp_ver
    echo "Installed WiringPi version: $wp_ver"
    if [ "$wp_ver" != "$CURRENT_WP_VER" ] ; then
        echo "Installing latest version of WiringPi"
        # Setup tmp directory
        if [ ! -d "$SRCDIR" ] ; then
            mkdir "$SRCDIR"
        fi

        # Need wiringPi version 2.60 for Raspberry Pi 400 which is not yet
        # in Debian repos.
        # The following does not work.
        #   wget -P /usr/local/src https://project-downloads.drogon.net/wiringpi-latest.deb
        #   sudo dpkg -i /usr/local/src/wiringpi-latest.deb

        pushd $SRCDIR
        git clone https://github.com/WiringPi/WiringPi
        cd WiringPi
        ./build
        gpio -v
        popd > /dev/null

        get_wp_ver
        echo "New WiringPi version: $wp_ver"
    fi
}

# ===== main

# Check if running as root
if [[ $EUID != 0 ]] ; then
   USER=$(whoami)
   dbgecho "Running as user: $USER"
else
    echo
    echo "Not required to be root to run this script."
    exit 1
fi

userbindir="/home/$USER/bin"

# If there are any args on the command line just copy files in current
# directory to local bin dir

if [[ $# -gt 0 ]] ; then
    # Specify source directory as current directory
    # Used during debug
    copy_local_bin "."
    exit 0
fi

NEEDPKG_FLAG=false

## Verify required programs are installed

for prog_name in `echo ${PROGLIST}` ; do
   echo "DEBUG: is program: $prog_name installed"
   type -P $prog_name &> /dev/null
   if [ $? -ne 0 ] ; then
      echo "$scriptname: Need to Install $prog_name program"
      NEEDPKG_FLAG=true
   fi
done
if [ "$NEEDPKG_FLAG" = "true" ] ; then
    echo "Installing required packages "
    dbgecho "Debian packages: for aplay install alsa-utils"
    PROGLIST="alsa-utils $PROGLIST"
    sudo apt-get -y -q install $PROGLIST
    if [[ $? > 0 ]] ; then
        echo "$(tput setaf 1)Failed to install $PROGLIST, install from command line. $(tput sgr0)"
    fi
fi

# Check for latest verion of WiringPi
chk_wp_ver

## Edit direwolf.conf

# Changes to Channel(0,1) section
#  Add these lines
#   ARATE 48000
#   DTMF
#   TTOBJ 0 APP

# Set ARATE 48000 if not already set
dbgecho "Verify direwolf configuration"
grep -q "^ARATE 48000" $DIREWOLF_CFGFILE
if [ "$?" -ne 0 ] ; then
    # Add ARATE config after ACHANNELS command
    sudo sed -i -e '/^ACHANNELS .*/a ARATE 48000' $DIREWOLF_CFGFILE
else
    echo "ARATE parameter already set to 48000 in direwolf config file."
fi

grep -q "^DTMF" $DIREWOLF_CFGFILE
if [ "$?" -ne 0 ] ; then
#    sudo sed -i -e '/^CHANNEL 0.*/a DTMF\nTTOBJ 0 1 WIDE-1' $DIREWOLF_CFGFILE
    sudo sed -i -e '/^CHANNEL 0.*/a DTMF\nTTOBJ 0 APP' $DIREWOLF_CFGFILE
else
    echo "DTMF already configured in $DIREWOLF_CFGFILE"
fi

# Changes in DTMF section
# Add these lines
#   TTMHEAD BAxxxxxx
#   TTCMD /home/$USER/bin/dw-ttcmd.sh

grep -q "^TTCMD" $DIREWOLF_CFGFILE
if [ "$?" -ne 0 ] ; then
    sudo sed -i -e "/^#DWAIT.*/a TTMHEAD BAxxxxxx\nTTCMD /home/$USER/bin/dw-ttcmd.sh" $DIREWOLF_CFGFILE
else
    echo "TTCMD already configured in $DIREWOLF_CFGFILE"
fi

## Copy baud rate change scripts to local bin
copy_local_bin "/home/$USER/n7nix/baudrate"

# after making changes to direwolf config need to restart direwolf
$userbindir/ax25-restart  > /dev/null 2>&1

echo "$(date "+%Y %m %d %T %Z"): $scriptname: Touch Tone speed change install script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
echo
