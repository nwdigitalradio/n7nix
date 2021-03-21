#!/bin/bash
#
# script: split_ctrl.sh
#
# Script to install split-channel functionality allowing VHF/UHF
# packet on one audio channel & an HF program like fldigi on the other.
#
# This script defaults to packet/direwolf on left channel and HF on
# right channel.
#
# Refer to the following repo:
#  https://github.com/nwdigitalradio/split-channels
#
# Functionality (See usage function)
#
#  Display split channel status
#   ./split_ctrl.sh
#   ./split_ctrl.sh -s
#
#  Install split channel:
#   ./split_ctrl.sh -c left
#   ./split_ctrl.sh left
#
#  Stop using split channel
#   ./split_ctrl.sh off
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
# This script ADDS these files:
#  /etc/asound.conf
#  /etc/pulse/client.conf
#  /etc/pulse/daemon.conf
#  /etc/pulse/default.pa
#  /etc/pulse/sytem.pa
# In development:
#  /etc/systemd/system/pulseaudio.service
#
#
# This script MODIFYS the direwolf config file:
# /etc/direwolf.conf
#
# Uncomment this statement for debug echos
#DEBUG=1
FORCE_COPY="ON"

scriptname="`basename $0`"

PORT_CFG_FILE="/etc/ax25/port.conf"
DIREWOLF_CFGFILE="/etc/direwolf.conf"

USER=
SYSTEMCTL="systemctl"

# File locations for pulseaudio systemd service file
SYSD_SYS_ETC_DIR="/etc/systemd/system"
SYSD_SYS_LIB_DIR="/usr/lib/systemd/system"

SYSD_USER_ETC_DIR="/etc/systemd/user"
SYSD_USER_LIB_DIR="/usr/lib/systemd/user"

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

# ===== function get_service type
# Determine if this is a 'user' or 'system' service file\
# Also set SYSD_NAME to system or usr
#
function get_service_type() {

    service_name="$1"
    extension="${service_name##*.}"
    echo "DEBUG: ${FUNCNAME[0]}: name: $service_name, extension: $extension"

    if [ "$service_name" = "$extension" ] ; then
        echo
        echo "NO file name extension found adding .service"
	service_name=$service_name.service
	service=$service_name.service
    else
        echo
        echo "Found file name extension: $extension"
    fi

    SYSD_TYPE="--system"
    SYSD_NAME="system"

    # Force systemd 'system'
    if [ 1 -eq 0 ] ; then
        if [ -s $SYSD_USER_ETC_DIR/$service_name ] || [ -s $SYSD_USER_LIB_DIR/$service_name ] ; then
            SYSD_TYPE="--user"
	    SYSD_NAME="user"
        fi
    fi

    if [ 1 -eq 0 ] ; then
    echo
    echo "DEBUG: $SYSD_USER_ETC_DIR/$service_name"
    ls -al $SYSD_USER_ETC_DIR/$service_name
    echo "DEBUG: $SYSD_USER_LIB_DIR/$service_name"
    ls -al $SYSD_USER_LIB_DIR/$service_name
    echo "DEBUG: setting systemd type to $SYSD_NAME for service $service_name"
    echo
    fi
}

# ===== function start_service
function start_service() {
    service="${1}.service"

    get_service_type $service

    systemctl $SYSD_TYPE is-enabled "$service" > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "ENABLING service: ($SYSD_NAME) $service"
        $SYSTEMCTL $SYSD_TYPE enable "$service"
        if [ "$?" -ne 0 ] ; then
            echo " Problem ENABLING ($SYSD_NAME) $service"
        fi
    else
        echo "${FUNCNAME[0]}: service: $service already enabled"
    fi

    if systemctl $SYSD_TYPE is-active --quiet "$service" ; then
        echo "Starting service but service: $service ($SYSD_NAME) is already running"
    else

        echo "STARTING service: ($SYSD_NAME) $service"
        $SYSTEMCTL $SYSD_TYPE --no-pager start "$service"
        if [ "$?" -ne 0 ] ; then
            echo " Problem starting ($SYSD_NAME) $service"
        fi
    fi
}

# ===== function stop_service
function stop_service() {
    service="$1"

    if [ -z "$2" ] ; then
        get_service_type $service
    else
       SYSD_TYPE="--$2"
       SYSD_NAME=$2
    fi

    systemctl $SYSD_TYPE is-active --quiet "$service"
    if [ $? -eq 0 ] ; then
        echo "STOPPING service: ($SYSD_NAME) $service"
	if [ "$SYSD_NAME" = "user" ] ; then
	    systemctl $SYSD_TYPE stop "$service"
        else
            $SYSTEMCTL $SYSD_TYPE stop "$service"
	fi
        if [ "$?" -ne 0 ] ; then
            echo " Problem STOPPING ($SYSD_NAME) $service"
        fi
    else
        echo "Stopping service but service: $service ($SYSD_NAME) is already stopped"
    fi

    systemctl $SYSD_TYPE is-enabled "$service" > /dev/null 2>&1
    if [ $? -eq 0 ] ; then
        echo "DISABLING ($SYSD_NAME) $service"
	if [ "$SYSD_NAME" = "user" ] ; then
            systemctl $SYSD_TYPE disable "$service"
        else
            $SYSTEMCTL $SYSD_TYPE disable "$service"
	fi
        if [ "$?" -ne 0 ] ; then
            echo " Problem DISABLING ($SYSD_NAME) $service"
        fi
    else
        echo " Service ($SYSD_NAME): $service already disabled."
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

    echo -n "  Diff asound config: ret: "
    diff asound.conf /etc/asound.conf
    retcode="$?"
    echo "$retcode"
    if [ "$retcode" -eq 2 ] ; then
        echo "Update asound.conf"
        sudo cp asound.conf /etc/asound.conf
    fi

    echo "  Diff pulse config"
    diff -bwBr --brief pulse /etc/pulse

    echo "  Diff pulse audio systemd user start service"
    diff systemd/system/pulseaudio.service /usr/lib/systemd/user

    echo "  Diff pulse audio systemd system start service"
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

    echo
    echo "=== Configure direwolf for 1 channel only"

    # - only CHANNEL 0 is used
    # Change ACHANNELS from 2 to 1
    dbgecho "ACHANNELS set to 1"
    sudo sed -i -e '/^ACHANNELS 2/ s/2/1/' "$DIREWOLF_CFGFILE"
    if [ $? -ne 0 ] ; then
        echo "${FUNCNAME[0]}: failed to edit $DIREWOLF_CFGFILE"
    fi

    # Define ARATE 48000 if not already set
    dbgecho "Add ARATE"
    grep "^ARATE 48000" $DIREWOLF_CFGFILE
    if [ $? -ne 0 ] ; then
        sudo sed -i -e '/^ACHANNELS 1.*/a ARATE 48000' $DIREWOLF_CFGFILE
        if [ $? -ne 0 ] ; then
            echo "${FUNCNAME[0]}: failed to edit $DIREWOLF_CFGFILE"
        fi
        echo "ARATE parameter added to $DIREWOLF_CFGFILE"
    else
        echo "ARATE parameter already set in direwolf config file."
    fi

    # Change ADEVICE:
    #   was: ADEVICE plughw:CARD=udrc,DEV=0 plughw:CARD=udrc,DEV=0
    #   now: ADEVICE draws-capture-left draws-playback-left

    sudo sed -i -e "/^ADEVICE plughw:CARD=/ s/^ADEVICE plughw:CARD=.*/ADEVICE draws-capture-$CONNECTOR draws-playback-$CONNECTOR/" "$DIREWOLF_CFGFILE"
    if [ $? -ne 0 ] ; then
        echo "${FUNCNAME[0]}: failed to edit ADEVICE $DIREWOLF_CFGFILE"
    fi

    echo "Verify ADEVICE parameter"
    grep -i "^ADEVICE" $DIREWOLF_CFGFILE

    # comment out second channel configuration in direwolf config file
    # sed -i -e "/\[pi4\]/,/\[/ s/^dtoverlay=.*/#&/" $BOOT_CFG_FILE
    # Add comment character
    sudo  sed -i -e '/^CHANNEL 1/,/^$/ s/^\(^PTT GPIO.*\)/#\1/g' "$DIREWOLF_CFGFILE"
    if [ $? -ne 0 ] ; then
        echo "${FUNCNAME[0]}: failed to edit PTT in $DIREWOLF_CFGFILE"
    fi
    sudo sed -i -e '/^CHANNEL 1/,/^$/ s/^\(^MODEM.*\)/#\1/g'    "$DIREWOLF_CFGFILE"
    if [ $? -ne 0 ] ; then
        echo "${FUNCNAME[0]}: failed to edit MODEM in $DIREWOLF_CFGFILE"
    fi
    sudo sed -i -e '/^CHANNEL 1/,/^$/ s/^\(^MYCALL.*\)/#\1/g'   "$DIREWOLF_CFGFILE"
    if [ $? -ne 0 ] ; then
        echo "${FUNCNAME[0]}: failed to edit MYCALL in $DIREWOLF_CFGFILE"
    fi
    sudo sed -i -e '/CHANNEL 1/,/^$/ s/^\(^CHANNEL.*\)/#\1/g'   "$DIREWOLF_CFGFILE"
    if [ $? -ne 0 ] ; then
        echo "${FUNCNAME[0]}: failed to edit CHANNEL in $DIREWOLF_CFGFILE"
    fi
}

# ===== function config_dw_2chan
# Edit direwolf.conf to use both channels (channel 0 & 1) of a DRAWS
# HAT

function config_dw_2chan() {

    echo "Edit direwolf config file to use 2 channels"

    #  - both CHANNELS are used for packet
    # Change ACHANNELS from 1 to 2
    dbgecho "ACHANNELS set to 2"
    sudo sed -i -e '/^ACHANNELS 1/ s/1/2/' "$DIREWOLF_CFGFILE"
    if [ $? -ne 0 ] ; then
        echo "${FUNCNAME[0]}: failed to edit CHANNELS in $DIREWOLF_CFGFILE"
    fi

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

    sudo sed -i -e "0,/^ADEVICE .*/ s/^ADEVICE .*/ADEVICE plughw:CARD=udrc,DEV=0 plughw:CARD=udrc,DEV=0/" "$DIREWOLF_CFGFILE"
    if [ $? -ne 0 ] ; then
        echo "${FUNCNAME[0]}: failed to edit ADEVICE in $DIREWOLF_CFGFILE"
    fi

    echo "Verify ADEVICE parameter"
    grep -i "^ADEVICE" $DIREWOLF_CFGFILE

    # Set up the second channel
    # CHANGE: THIS NEEDS SOME WORK
    uncomment_second_chan
    # sed -i -e "/#CHANNEL 1/ s/#CHANNEL 1/CHANNEL 1\nPTT GPIO $chan2ptt_gpio\nMODEM 1200\nMYCALL $CALLSIGN1\n/" $DIREWOLF_CFGFILE
}

# ===== function turn split channel on in port file

function port_split_chan_on() {

    echo "Enable split channels port file, Direwolf has left channel, HF has right channel"

    sudo sed -i -e "/\[port1\]/,/\[/ s/^speed=.*/speed=off/" "$PORT_CFG_FILE"
    if [ $? -ne 0 ] ; then
        echo "${FUNCNAME[0]}: failed to edit speed in $PORT_CFG_FILE"
    fi

    bsplitchannel=true
}

# ===== function turn split channel off in port file

function port_split_chan_off() {

    echo "DISable split channels, Direwolf controls left & right channels"

    sudo sed -i -e "/\[port1\]/,/\[/ s/^speed=.*/speed=1200/" "$PORT_CFG_FILE"
    if [ $? -ne 0 ] ; then
        echo "${FUNCNAME[0]}: failed to edit speed in $PORT_CFG_FILE"
    fi
}

# ===== function split_chan_on

function split_chan_on() {

    echo
    echo "=== ${FUNCNAME[0]}"

    service="pulseaudio"
    if systemctl $SYSD_TYPE is-active --quiet "$service" ; then
        echo "Service ($SYSD_TYPE): $service is already running"
    else
        start_service $service
    fi

    config_dw_1chan

    port_split_chan_on
    # restart direwolf/ax.25
    echo
    echo " == Restart direwolf"
    ax25-restart
}

# ===== function split_chan_off

function split_chan_off() {
    service="pulseaudio"

    get_service_type

    if systemctl $SYD_TYPE is-active --quiet "$service" ; then
        stop_service $service
    else
        echo "Service ($SYD_TYPE): $service is already stopped"
    fi

    config_dw_2chan
    port_split_chan_off
    # restart direwolf/ax.25
    echo
    echo " == Restart direwolf"
    ax25-restart
}

# ==== function copy_config
# Copy some of the config files from split-channels repository

function copy_config() {

    cd "$SPLIT_DIR"
    echo "Copy asound config"
    sudo cp -u etc/asound.conf /etc/asound.conf
    echo "Copy pulse config"
    sudo rsync -av etc/pulse/ /etc/pulse
    echo "Copy pulse audio systemd SYSTEM start service"
    sudo cp -u etc/systemd/system/pulseaudio.service /etc/systemd/system
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
        copy_config
    else
        if [ "$FORCE_COPY" = "ON" ] ; then
	    copy_config
	else
            echo
            echo "$(tput setaf 6)asound config file & pulse config directory already exist, NO config files copied, $(tput sgr0)"
	    echo
            do_diff
	fi
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
    service="${1}.service"

    get_service_type $service

    if systemctl $SYSD_TYPE is-enabled --quiet "$service" ; then
        enabled_str="IS enabled"
    else
        enabled_str="NOT enabled"
    fi

    if systemctl $SYSD_TYPE is-active --quiet "$service" ; then
        active_str="IS running"
    else
        active_str="NOT running"
    fi
    echo "Service: $service, $SYSD_NAME is $enabled_str and $active_str"
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
            echo -e "Direwolf IS running with pid: $pid, Split channel IS enabled\n  Direwolf controls $chan_lr channel only"
        else
            echo "Direwolf IS running with pid: $pid and controls both channels"
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
        echo "                  No args will display status of split channel"
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
    echo "Can not run this script as root"
    exit 1
fi

TMPDIR=/home/$USER/tmp
# local repository directory
REPO_DIR="/home/$USER/dev/github"
SPLIT_DIR="$REPO_DIR/split-channels"

# Setup tmp directory
if [ ! -d "$TMPDIR" ] ; then
  mkdir "$TMPDIR"
fi

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
	    echo
	    echo " == Display Split Channel Status"
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

stop_service pulseaudio user
stop_service pulseaudio system

echo
echo "=== Start split channel install"
split_chan_install

# Setup split channel
echo
echo "=== Start pulse audio service"
start_service pulseaudio

echo
echo "=== Turn on split channel services"
split_chan_on

# may need to do the following:
# chmod 000 /usr/bin/start-pulseaudio-x11
