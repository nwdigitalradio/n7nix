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

# ===== function stop_sys_service
function stop_sys_service() {
    service="$1"
    systemctl is-enabled "$service" > /dev/null 2>&1
    if [ $? -eq 0 ] ; then
        echo "DISABLING $service"
        $SYSTEMCTL disable "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem DISABLING $service"
        fi
    else
        echo "Service: $service already disabled."
    fi
    $SYSTEMCTL stop "$service"
    if [ "$?" -ne 0 ] ; then
        echo "Problem STOPPING $service"
    fi
}

# ===== function stop_user_service
function stop_user_service() {
    service="$1"
    systemctl --user is-enabled "$service" > /dev/null 2>&1
    if [ $? -eq 0 ] ; then
        echo "DISABLING (user)$service"
        $SYSTEMCTL --user disable "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem DISABLING (user) $service"
        fi
    else
        echo "Service (user): $service already disabled."
    fi
    $SYSTEMCTL --user stop "$service"
    if [ "$?" -ne 0 ] ; then
        echo "Problem STOPPING (user) $service"
    fi
}

# ===== function do_diff
# Diff installed files with repo files
function do_diff() {

    # Is pulse audio installed?
    packagename="pulseaudio"
    is_pkg_installed $packagename
    if [ $? -ne 0 ] ; then
        echo "No package: $packagename found"
    else
        # Found package, will continue
        echo "Detected $packagename package."
    fi

    # Check for split-channels source directory
    if [ ! -d "$SPLIT_DIR" ] ; then
        echo "  No split-channels source directory found ($SPLIT_DIR)"
        return
    else
        echo "  Found split-channels source directory: $SPLIT_DIR"
    fi

    # DIFF files
    # Start from the split-channels repository directory
    cd "$SPLIT_DIR/etc"

    echo "  Diff asound config"
    diff asound.conf /etc/asound.conf
    echo "  Diff pulse config"
    diff -bwBr --brief pulse /etc/pulse

    echo "  Diff pulse audio systemd start service"
    diff systemd/system/pulseaudio.service /etc/systemd/system

    # Diff direwolf configuration
    echo "  Diff direwolf config file"
    if [ -e /home/$USER/tmp/direwolf.conf ] ; then
        diff /home/$USER/tmp/direwolf.conf $DIREWOLF_CFGFILE
    else
        echo "  Save a copy of direwolf configuration file."
        cp $DIREWOLF_CFGFILE /home/$USER/tmp/
    fi
}

# ===== function config_dw_1chan

# comment out second channel in direwolf config file

function config_dw_1chan() {

    echo "Edit direwolf config file to use 1 chan"

    # - only CHANNEL 0 is used
    # Change ACHANNELS from 2 to 1
    dbgecho "ACHANNELS set to 1"
    sudo sed -i -e '/^ACHANNELS 2/ s/2/1/' $DIREWOLF_CFGFILE

    # Define ARATE 48000 if not already set
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

    sudo sed -i -e "/^ADEVICE plughw:CARD=/ s/^ADEVICE plughw:CARD=.*/ADEVICE draws-capture-$CONNECTOR draws-playback-$CONNECTOR/" $DIREWOLF_CFGFILE

    echo "Verify ADEVICE parameter"
    grep -i "^ADEVICE" $DIREWOLF_CFGFILE

    # comment out second channel configuration in direwolf config file
    # sed -i -e "/\[pi4\]/,/\[/ s/^dtoverlay=.*/#&/" $BOOT_CFG_FILE
    # Add comment character
    sed -i -e '/^CHANNEL 1/,/^$/ s/^\(^PTT GPIO.*\)/#\1/g'  "$DIREWOLF_CFGFILE"
    sed -i -e '/^CHANNEL 1/,/^$/ s/^\(^MODEM.*\)/#\1/g'  "$DIREWOLF_CFGFILE"
    sed -i -e '/^CHANNEL 1/,/^$/ s/^\(^MYCALL.*\)/#\1/g'  "$DIREWOLF_CFGFILE"
    sed -i -e '/CHANNEL 1/,/^$/ s/^\(^CHANNEL.*\)/#\1/g'  "$DIREWOLF_CFGFILE"
}

# ===== function config_dw_2chan
# Edit direwolf.conf to use both channels (channel 0 & 1) of a DRAWS
# HAT

function config_dw_2chan() {

    echo "Edit direwolf config file to use 2 channels"

    #  - both CHANNELS are used for packet
    # Change ACHANNELS from 1 to 2
    dbgecho "ACHANNELS set to 2"
    sudo sed -i -e '/^ACHANNELS 1/ s/1/2/' $DIREWOLF_CFGFILE

    # Leave ARATE 48000 unchanged
    dbgecho "Check for ARATE parameter"
    grep "^ARATE 48000" $DIREWOLF_CFGFILE
    if [ $? -ne 0 ] ; then
        echo "ARATE parameter NOT found."
    else
        echo "ARATE parameter already set in direwolf config file."
    fi

    # Change ADEVICE:
    #  to: ADEVICE plughw:CARD=udrc,DEV=0 plughw:CARD=udrc,DEV=0

    sudo sed -i -e "0,/^ADEVICE .*/ s/^ADEVICE .*/ADEVICE plughw:CARD=udrc,DEV=0 plughw:CARD=udrc,DEV=0/"  $DIREWOLF_CFGFILE

    echo "Verify ADEVICE parameter"
    grep -i "^ADEVICE" $DIREWOLF_CFGFILE

    # Set up the second channel
    # CHANGE: THIS NEEDS SOME WORK
    uncomment_second_chan
    # sed -i -e "/#CHANNEL 1/ s/#CHANNEL 1/CHANNEL 1\nPTT GPIO $chan2ptt_gpio\nMODEM 1200\nMYCALL $CALLSIGN1\n/" $DIREWOLF_CFGFILE
}

# ===== function turn split channel on in port file

function port_split_chan_on() {

    echo "Enable split channels, Direwolf has left channel, HF has right channel"

    sudo sed -i -e "/\[port1\]/,/\[/ s/^speed=.*/speed=off/" $PORT_CFG_FILE

    bsplitchannel=true
}

# ===== function turn split channel off in port file

function port_split_chan_off() {

    echo "DISable split channels, Direwolf controls left & right channels"

    sudo sed -i -e "/\[port1\]/,/\[/ s/^speed=.*/speed=1200/" $PORT_CFG_FILE
}

# ===== function split_chan_on

function split_chan_on() {

    service="pulseaudio"
    if systemctl is-active --quiet "$service" ; then
        echo "Service (sys): $service is already running"
    elif systemctl --user is-active --quiet "$service" ; then
        echo "Service (user): $service is already running"
    else
        start_service $service
    fi

    config_dw_1chan
    port_split_chan_on
    # restart direwolf/ax.25
    ax25-stop
    ax25-start
}

# ===== function split_chan_off

function split_chan_off() {
    service="pulseaudio"
    if systemctl is-active --quiet "$service" ; then
        stop_sys_service $service
    elif systemctl --user is-active --quiet "$service" ; then
        stop_user_service $service
    else
        echo "Service: $service is already stopped"
    fi

    config_dw_2chan
    port_split_chan_off
    # restart direwolf/ax.25
    ax25-stop
    ax25-start
}

# ==== function split_chan_install
# Install pulse audio
# Install split channel files from repo
# Copy configuration files to /etc

function split_chan_install() {

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

    # Copy asound & pulse configuration files
    # Copy pulseaudio systemd file

    # Start from the split-channels repository directory
    cd "$SPLIT_DIR/etc"
    PULSE_CFG_DIR="/etc/pulse"

    # NEEDS WORK ...
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
        echo
        echo "$(tput setaf 6)asound config file & pulse config directory already exist, NO config files copied$(tput sgr0)"
	echo
        do_diff
    fi
}

# ===== function is_direwolf
# Determine if direwolf is running

function is_direwolf() {
    # ardop will NOT work if direwolf or any other sound card program is running
    pid=$(pidof direwolf)
    retcode="$?"
    return $retcode
}

# ===== function is_pulseaudio
# Determine if pulse audio is running

function is_pulseaudio() {
    pid=$(pidof pulseaudio)
    retcode="$?"
    return $retcode
}
# ===== function is_splitchan

function is_splitchan() {

    retcode=1

    # ==== verify port config file
    if [ -e "$PORT_CFG_FILE" ] ; then
        portname=port1
        PORTSPEED=$(sed -n "/\[$portname\]/,/\[/p" $PORT_CFG_FILE | grep -i "^speed" | cut -f2 -d'=')

        case $PORTSPEED in
            1200 | 9600)
                dbgecho "parse baud_$PORTSPEED section for $portname"
            ;;
            off)
                echo "Using split channel, port: $portname is off"
                retcode=0
            ;;
            *)
                echo "Invalid speed parameter: $PORTSPEED, found in $PORT_CFG_FILE"
            ;;
        esac

    else
        # port config file does NOT exist
        echo "Port config file: $PORT_CFG_FILE NOT found."
        retcode=3
    fi
    return $retcode
}

# ===== function display_service_status
function display_service_status() {
    service="$1"
    if systemctl is-enabled --quiet "$service" ; then
        enabled_str="enabled"
    else
        enabled_str="NOT enabled"
    fi

    if systemctl is-active --quiet "$service" ; then
        active_str="running"
    else
        active_str="NOT running"
    fi
    echo "Service: $service is $enabled_str and $active_str"
}

# ===== function verify direwolf
# ==== verify direwolf configuration

function verify_direwolf() {
    is_direwolf
    if [ "$?" -eq 0 ] ; then
        # Direwolf is running, check for split channels
        is_splitchan
        if [ "$?" -eq 0 ] ; then
            # Get 'left' or 'right' channel from direwolf config (last word in ADEVICE string)
            chan_lr=$(grep "^ADEVICE " $DIREWOLF_CFGFILE | grep -oE '[^-]+$')
            echo -e "Direwolf is running with pid: $pid, Split channel is enabled\n  Direwolf controls $chan_lr channel only"
        else
            echo "Direwolf is running with pid: $pid and controls both channels"
        fi
    else
        echo "Direwolf is NOT running"
    fi

    echo -n "  Check: "
    grep "^ADEVICE" $DIREWOLF_CFGFILE

    echo -n "  Check: "
    grep -q "^ARATE " $DIREWOLF_CFGFILE
    if [ $? -ne 0 ] ; then
        echo "ARATE parameter NOT set in $DIREWOLF_CFGFILE"
    else
        arateval=$(grep "^ARATE " $DIREWOLF_CFGFILE | cut -f2 -d' ')
        echo "ARATE parameter already set to $arateval in direwolf config file."
    fi

    num_chan=$(grep "^ACHANNELS " $DIREWOLF_CFGFILE | cut -f2 -d' ')
    echo "  Number of direwolf channels: $num_chan"
}


# ===== Split channel status
function split_chan_status() {

    # ==== verify pulse audio
    packagename="pulseaudio"
    is_pkg_installed $packagename
    if [ $? -ne 0 ] ; then
        echo "  No package $packagename NOT found"
    else
        # Found package
        echo "  Detected $packagename package."
    fi

    is_pulseaudio
    if [ "$?" -ne 0 ] ; then
        echo " == Pulse Audio is NOT RUNNING."
    else
        pactl list sinks | grep -A3 "Sink #"
    fi

    # ==== verify split channel repo
    # is split channel repo installed
    if [ ! -e "$SPLIT_DIR" ] ; then
        state="does NOT"
    else
        state="DOES"
    fi
    echo "split-channels repo $state exist"

    # ==== verify pulseaudio & asound config files
    if [ -e "/etc/asound.conf" ] ; then
        state="DOES"
    else
        state="does NOT"
    fi
    echo "asound config file $state exist"

    if [ -d "/etc/pulse" ] ; then
        state="DOES"
    else
        state="does NOT"
    fi
    echo "Pulseaudio configuration directory $state exist"

    # ==== verify pulse audio service
    display_service_status "pulseaudio"

    # ==== verify direwolf
    verify_direwolf

    do_diff

}

# ===== Display program help info
#
usage () {
	(
	echo "Usage: $scriptname [-c <connector>][-s][-d][-h][left|right|off]"
        echo "                  No args will install & configure pulseaudio, split channel"
        echo "  left            ENable split channel, direwolf uses left connector"
        echo "  right           ENable split channel, direwolf uses right connector NOT IMPLEMENTED"
        echo "  off             DISable split channel"
        echo "  -c right | left ENable split channel, use either right or left mDin6 connector."
        echo "  -s              Display verbose status"
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
    dbgecho "set sudo as user $USER"
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

# default to show split channel status
if [[ $# -eq 0 ]] ; then
    split_chan_status
    exit 0
fi

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
        -s | status)
            split_chan_status
            exit 0
        ;;
        -h)
            usage
            exit 0
        ;;
        left|LEFT)
            CONNECTOR="left"
        ;;
        right|RIGHT)
            CONNECTOR="right"
        ;;
        off|OFF)
            split_chan_off
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

split_chan_install
# Setup split channel
start_service pulseaudio
config_dw_1chan
split_chan_on

# may need to do the following:
# chmod 000 /usr/bin/start-pulseaudio-x11
