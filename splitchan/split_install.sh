#!/bin/bash
#
# Script to install split-channels functionality allowing VHF/UHF
# packet on one audio channel & an HF program like fldigi on the other.
# Refer to this repo: https://github.com/nwdigitalradio/split-channels
#
# Direwolf and any other programs should use the following ALSA audio
# devices for the right DRAWS mini din connector only:
#
# draws-capture-right
# draws-playback-right
#
# As you would guess, to use the DRAWS left mini din connector with
# direwolf then:
#
# draws-capture-left
# draws-playback-left
#
# Not recommended to mess around with the sound too much in the GUI
# while in this configuration.
#
# If the Raspberry Pi onboard audio interface has been enabled in
# config.txt this setup will attempt to use it as a monitor channel.
#
# For HDMI audio in an HDMI monitor/TV:
# amixer -D hw:CARD=ALSA cset numid=3 2
#
# For the headphone jack on the Pi:
# amixer -D hw:CARD=ALSA cset numid=3 1
#
# Uncomment this statement for debug echos
#DEBUG=1

scriptname="`basename $0`"

DIREWOLF_CFGFILE="/etc/direwolf.conf"
USER=
# Set connector to be either left or right
# This selects which mini din 6 connector to use on the DRAWS card.
CONNECTOR="left"


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

# ===== function start_service

function start_service() {
    service="$1"
    echo "Starting: $service"

    systemctl is-enabled "$service" > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "ENABLING $service"
        $SYSTEMCTL enable "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem ENABLING $service"
        fi
    fi
    $SYSTEMCTL --no-pager start "$service"
    if [ "$?" -ne 0 ] ; then
        echo "Problem starting $service"
    fi
}

# ===== main

# Check if we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Not running as root, will use sudo"
fi

# Is pulse audio installed?
packagename="pulseaudio"
is_pkg_installed $packagename
if [ $? -ne 0 ] ; then
    echo "$scriptname: No package found: Installing $packagename"
    apt-get install $packagename
else
    # Found package, will continue
    echo "$scriptname: Detected $packagename package."
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

REPO_DIR="/home/$USER/dev/github"
SPLIT_DIR="$REPO_DIR/split-channels"

# Check for repository directory
if [ ! -e "$REPO_DIR" ] ; then
    mkdir -p "$REPO_DIR"
fi

# Check for split-channels source directory
if [ ! -e "$SPLIT_DIR" ] ; then
    git clone "https://github.com/nwdigitalradio/split-channels"
    if [ "$?" -ne 0 ] ; then
      echo "$(tput setaf 1)Problem cloning repository $repo_name$(tput setaf 7)"
      exit 1
else
    cd "$SPLIT_DIR"
    sudo git pull
fi

# Copy files
# Start from the split-channels repository directory
cd "$SPLIT_DIR/etc"

echo "Copy asound config"
sudo cp asound.conf
echo "Copy pulse config"
sudo rsync -av pulse /etc/
echo "Copy pulse audio systemd start service"
sudo cp systemd/system/pulseaudio.service /etc/systemd/system

# Modify direwolf configuration
echo "Edit direwolf config file"
#  - only CHANNEL 0 is used
# Change ACHANNELS from 2 to 1
dbgecho "ACHANNELS"
sed -i -e '/^ACHANNELS 2/ s/1/2/' $DIREWOLF_CFGFILE

# Define ARATE 48000
dbgecho "Add ARATE"
grep "^ARATE 4800" $DIREWOLF_CFGFILE
if [ $? -ne 0 ] ; then
    sed -i -e '/^ACHANNELS 1.*/a ARATE 4800' $DIREWOLF_CFGFILE
    echo "ARATE parameter addedt to $DIRWOLF_CFGFILE"
fi

# Change ADEVICE:
#   was: ADEVICE plughw:CARD=udrc,DEV=0 plughw:CARD=udrc,DEV=0
#   now: ADEVICE draws-capture-left draws-playback-left
dbgecho "ADEVICE"
sed -i -e '/^ADEVICE  plughw:CARD=/ s/ADEVICE plughw:card=.*/ADEVICE draws-capture-left draws-playback-left/' $DIREWOLF_CFGFILE

start_service pulseaudio

# may need to do the following:
# chmod 000 /usr/bin/start-pulseaudio-x11