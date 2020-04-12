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
# This script adds these files:
#  /etc/asound.conf
#  /etc/pulse/client.conf
#  /etc/pulse/daemon.conf
#  /etc/pulse/default.pa
#  /etc/pulse/sytem.pa
#  /etc/systemd/system/pulseaudio.service
#
#
# This script will modify the direwolf config file:
# /etc/direwolf.conf
#
# Uncomment this statement for debug echos
#DEBUG=1

scriptname="`basename $0`"

PORT_CFG_FILE="/etc/ax25/port.conf"
DIREWOLF_CFGFILE="/etc/direwolf.conf"

USER=
SYSTEMCTL="systemctl"

# Set connector to be either left or right
# This selects which mini Din 6 connector DIREWOLF will use on the DRAWS card.
# Default: direwolf controls channel 0 for the left mini din connector.
# Note: if you choose "right", then direwolf channel 0 moves to the right connector

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

# ===== function get_user_name
function get_user_name() {

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

# ===== function do_diff
# Diff installed files with repo files
function do_diff() {

    # Is pulse audio installed?
    packagename="pulseaudio"
    is_pkg_installed $packagename
    if [ $? -ne 0 ] ; then
        echo "$scriptname: No package: $packagename found"
    else
        # Found package, will continue
        echo "$scriptname: Detected $packagename package."
    fi

    # Check for split-channels source directory
    if [ ! -e "$SPLIT_DIR" ] ; then
        echo "No split-channels source directory found ($SPLIT_DIR)"
        return
    else
        echo "Found split-channels source directory: $SPLIT_DIR"
    fi

    # DIFF files
    # Start from the split-channels repository directory
    cd "$SPLIT_DIR/etc"

    echo "Diff asound config"
    diff asound.conf /etc/asound.conf
    echo "Diff pulse config"
    diff -bwBr --brief pulse /etc/pulse

    echo "Diff pulse audio systemd start service"
    diff systemd/system/pulseaudio.service /etc/systemd/system

    # Diff direwolf configuration
    echo "Diff direwolf config file"
    if [ -e /home/$USER/tmp/direwolf.conf ] ; then
        diff /home/$USER/tmp/direwolf.conf /etc/direwolf.conf
    else
        echo "Save a copy of direwolf configuration file."
        cp /etc/direwolf.conf /home/$USER/tmp/
    fi
}

# ===== function comment out second channel in direwolf

function comment_second_chan() {
    # sed -i -e "/\[pi4\]/,/\[/ s/^dtoverlay=.*/#&/" $BOOT_CFG_FILE
    # Add comment character
    sed -i -e '/^CHANNEL 1/,/^$/ s/^\(^PTT GPIO.*\)/#\1/g'  "$DIREWOLF_CFGFILE"
    sed -i -e '/^CHANNEL 1/,/^$/ s/^\(^MODEM.*\)/#\1/g'  "$DIREWOLF_CFGFILE"
    sed -i -e '/^CHANNEL 1/,/^$/ s/^\(^MYCALL.*\)/#\1/g'  "$DIREWOLF_CFGFILE"
    sed -i -e '/CHANNEL 1/,/^$/ s/^\(^CHANNEL.*\)/#\1/g'  "$DIREWOLF_CFGFILE"
}


# ===== function turn split channel on

function split_chan_on() {

    echo "Enable split channels, Direwolf has left channel, HF has right channel"

    sudo sed -i -e "/\[port1\]/,/\[/ s/^speed=.*/speed=off/" $PORT_CFG_FILE

    bsplitchannel=true
}


# ===== Display program help info
#
usage () {
	(
	echo "Usage: $scriptname [-c][-V][-d][-h]"
        echo "                  No args will update all programs."
        echo "  -c right | left Specify either right or left mDin6 connector."
        echo "  -V              Displays differences of required programs."
        echo "  -d              Set DEBUG flag"
        echo "  -h              Display this message."
        echo
	) 1>&2
	exit 1
}

# ===== main

# Check if running as root
if [[ $EUID != 0 ]] ; then
    SYSTEMCTL="sudo systemctl"
    USER=$(whoami)
    echo "set sudo as user $USER"
else
    # Running as root
    get_user_name
fi

TMPDIR=/home/$USER/tmp

# Setup tmp directory
if [ ! -d "$TMPDIR" ] ; then
  mkdir "$TMPDIR"
fi

REPO_DIR="/home/$USER/dev/github"
SPLIT_DIR="$REPO_DIR/split-channels"

# Check for any command line arguments
# Command line args are passed with a dash & single letter
#  See usage function

while [[ $# -gt 0 ]] ; do

    key="$1"
    case $key in
        -d)
            DEBUG=1
        ;;
        -c)
            CONNECTOR="$2"
            shift # past argument
            if [ "$CONNECTOR" != "right" ] && [ "$CONNECTOR" != "left" ] ; then
                echo "Connector argument must either be left or right, found '$CONNECTOR'"
                exit
            fi
            echo "Set connector to: $CONNECTOR"
        ;;
        -V)
            do_diff
            exit
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

# Is pulse audio installed?
packagename="pulseaudio"
is_pkg_installed $packagename
if [ $? -ne 0 ] ; then
    echo "$scriptname: No package found: Installing $packagename"
    sudo apt-get install -y -q $packagename
else
    # Found package, will continue
    echo "$scriptname: Detected $packagename package."
fi

# Check for repository directory
if [ ! -e "$REPO_DIR" ] ; then
    mkdir -p "$REPO_DIR"
fi

# Check for split-channels source directory
echo "Check if directory: $SPLIT_DIR exists"
if [ ! -e "$SPLIT_DIR" ] ; then
    cd "$REPO_DIR"
    git clone "https://github.com/nwdigitalradio/split-channels"
    if [ "$?" -ne 0 ] ; then
        echo "$(tput setaf 1)Problem cloning repository $repo_name$(tput setaf 7)"
        exit 1
    fi
else
    echo "Updating split-channels repo"
    cd "$SPLIT_DIR"
    git pull
fi

# Copy files
# Start from the split-channels repository directory
cd "$SPLIT_DIR/etc"
ASOUND_CFG_FILE="/etc/asound.conf"
PULSE_CFG_DIR="/etc/pulse"

# If asound.conf or pulse config directory exists do NOT overwrite
# unless explicity (command line arg) told to

if [ ! -e $ASOUND_CFG_DIR ] && [ ! -d $PULSE_CFG_DIR ] ; then

    echo "Copy asound config"
    sudo cp -u asound.conf /etc/asound.conf
    echo "Copy pulse config"
    sudo rsync -av pulse/ /etc/pulse
    echo "Copy pulse audio systemd start service"
    sudo cp -u systemd/system/pulseaudio.service /etc/systemd/system
else
    echo "asound config file & pulse config directory already exist, NO config files copied"
    do_diff
fi

# Modify direwolf configuration
echo "Edit direwolf config file"

#  - only CHANNEL 0 is used
# Change ACHANNELS from 2 to 1
dbgecho "ACHANNELS set to 1"
sudo sed -i -e '/^ACHANNELS 2/ s/2/1/' $DIREWOLF_CFGFILE

# Define ARATE 48000
dbgecho "Add ARATE"
grep "^ARATE 48000" $DIREWOLF_CFGFILE
if [ $? -ne 0 ] ; then
    sudo sed -i -e '/^ACHANNELS 1.*/a ARATE 48000' $DIREWOLF_CFGFILE
    echo "ARATE parameter added to $DIREWOLF_CFGFILE"
else
    echo "ARATE parameter already set in direwolf config file."
fi


# Change ADEVICE:
#   was: ADEVICE plughw:CARD=udrc,DEV=0 plughw:CARD=udrc,DEV=0
#   now: ADEVICE draws-capture-left draws-playback-left
dbgecho "ADEVICE"
sudo sed -i -e "/^ADEVICE plughw:CARD=/ s/^ADEVICE plughw:CARD=.*/ADEVICE draws-capture-$CONNECTOR draws-playback-$CONNECTOR/" $DIREWOLF_CFGFILE

comment_second_chan

echo "DEBUG follows:"
grep -i "^ADEVICE" $DIREWOLF_CFGFILE

service="pulseaudio"
if systemctl is-active --quiet "$service" ; then
    echo "Service: $service is already running"
else
    start_service $service
fi

# And finally set up the port configuration file
split_chan_on

# may need to do the following:
# chmod 000 /usr/bin/start-pulseaudio-x11
