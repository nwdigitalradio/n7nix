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

# List of required programs
PROGLIST="gpio sox at"
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
    echo "Installing required packages"
    dbgecho "Debian packages: for aplay install alsa-utils, for gpio, install wiringpi"
    sudo apt-get -y -q install alsa-utils sox
    if [[ $? > 0 ]] ; then
        echo "$(tput setaf 1)Failed to install alsa-utils & sox, install from command line. $(tput sgr0)"
    fi
fi

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
