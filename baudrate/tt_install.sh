#!/bin/bash
#
#  tt_install.sh
#
# Install files to local bin and modify direwolf config to enable Touch
# Tone commands
#
# Uncomment this statement for debug echos
# DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
DIREWOLF_CFGFILE="/etc/direwolf.conf"

# ===== function dbgecho

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

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
PROGLIST="gpio sox"
NEEDPKG_FLAG=false

# Verify required programs are installed

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
fi


## Edit direwolf.conf
# Changes to Channel(0,1) section
#  Add these lines
#   ARATE 48000
#   DTMF
#   TTOBJ 0 APP

# SetARATE 48000 if not already set
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


# Copy baud rate change scripts to local bin

# Check if local bin directory exists.
if [ ! -d "$userbindir" ] ; then
   mkdir $userbindir
fi

cp -u /home/$USER/n7nix/baudrate/speed_switch.sh $userbindir
cp -u /home/$USER/n7nix/baudrate/dw-ttcmd.sh $userbindir
cp -u /home/$USER/n7nix/baudrate/send-ttcmd.sh $userbindir

echo "$(date "+%Y %m %d %T %Z"): $scriptname: Touch Tone speed change install script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
echo
