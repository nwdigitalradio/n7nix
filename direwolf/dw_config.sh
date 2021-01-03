#!/bin/bash
#
#  dw_config.sh
#
# direwolf configuration script
# Original made to config direwolf for 1200/9600 baud devices
#
# Config direwolf:
# 1. Either single or dual channel DRAWS
#  1a. Single channel could be split channel
#      packet on left connector, HF mode on the right
# 2. Single channel CM108 sound device (DINAH)
# 3. Virtual channel with two Direwolf channels on single radio channel
#
# drw=DRAWS RPi hat, usb=USB sound card
#
# drw 1: draws 1 chan 1200 or 9600
# drw 2: draws 2 chan 1200 or 9600
# usb 1: dinah 1 chan 1200 or 9600
#
# drw v:
# usb v:
#       draws | usb 1 chan, 2 virtual devices


scriptname="`basename $0`"
USER=
DEBUG=
DEVICE_TYPE="usb"
CHAN_NUM="1"
CALLSIGN="N0ONE"
SED="sudo sed"
SYSTEMCTL="systemctl"
b_painstall=false
PA_SCOPE=

DIREWOLF_CFGFILE="/etc/direwolf.conf"
AXPORTS_FILE="/etc/ax25/axports"

PULSEAUDIO_CFGFILE="/etc/asound.conf"
PULSE_CFG_DIR="/etc/pulse"

PTT_GPIO_CHAN0=12

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# ===== function config_pa
# Configure pulse audio
# if pulseaudio config file exists do not destroy it.

function config_pa() {

    if [ -f "$PULSEAUDIO_CFGFILE" ] ; then
        # get the path & filename without extension
        no_ext=${PULSEAUDIO_CFGFILE%.*}
	# This function determines an unused filename so that the
	# config file never gets over written.
        seq_backup "$no_ext"
        echo "Original pulseaudio config file saved as $fname"
    fi
    # This will bloto anything that is in the pulseaudio config file
    sudo tee $PULSEAUDIO_CFGFILE > /dev/null << EOT
pcm.draws-capture-left {
  type pulse
  device "draws-capture-left"
}
pcm.draws-playback-left {
  type pulse
  device "draws-playback-left"
}
pcm.draws-capture-right {
  type pulse
  device "draws-capture-right"
}
pcm.draws-playback-right {
  type pulse
  device "draws-playback-right"
}


pcm.draws-capture-left-sub {
  type pulse
  device "draws-capture-left"
}
pcm.draws-playback-left-sub {
  type pulse
  device "draws-playback-left"
}
pcm.draws-capture-right-sub {
  type pulse
  device "draws-capture-right"
}
pcm.draws-playback-right-sub {
  type pulse
  device "draws-playback-right"
}
EOT

}

# ===== function split_chan_status
# Check for split-channel repository

function split_chan_status() {

    echo "   == split_chan_status"
    # Check for split-channels source directory
    if [ ! -e "$SPLIT_DIR" ] ; then
        echo "NO split-channel repo dir found."
    else
        echo "split-channel directory: $SPLIT_DIR exists"
    fi

    if [ -f $PULSEAUDIO_CFGFILE ] ; then
        echo "File: $PULSEAUDIO_CFGFILE exists"
    else
        echo "Need file: $PULSEAUDIO_CFGFILE"
    fi

    if [ -d $PULSE_CFG_DIR ] ; then
        echo "pulse config directory exists"
    else
        echo "Need pulse config"
    fi
}

# ===== function check_split_chan_install
# Check for split-channel repository
# Copy files from split-channel repository for pulseaudio

function check_split_chan_install() {
    # Check for split-channel repository directory
    if [ ! -e "$REPO_DIR" ] ; then
        mkdir -p "$REPO_DIR"
    fi

    # Check for split-channels source directory
    echo "Check if directory: $SPLIT_DIR exists"
    if [ ! -e "$SPLIT_DIR" ] ; then
        cd "$REPO_DIR"
        git clone "https://github.com/nwdigitalradio/split-channels"
        if [ "$?" -ne 0 ] ; then
            echo "$(tput setaf 1)Problem cloning repository $repo_name$(tput sgr0)"
            exit 1
        fi
    else
        echo "Updating split-channels repo"
        cd "$SPLIT_DIR"
        git pull
    fi

    # Copy asound & pulseaudio configuration files

    # Start from the split-channels repository directory
    ## Save current directory
    pushd "$SPLIT_DIR/etc"

    # NEEDS WORK ...
    # If asound.conf or pulse config directory exists do NOT overwrite
    # unless explicity (command line arg) told to

    if [ -f $PULSEAUDIO_CFGFILE ] ; then
        echo "File: $PULSEAUDIO_CFGFILE already exists"
    else
        echo "Need file: $PULSEAUDIO_CFGFILE"
    fi
    config_pa

    if [ -d $PULSE_CFG_DIR ] ; then
        echo
        echo "$(tput setaf 6)asound config file & pulse config directory already exist, NO config files copied$(tput sgr0)"
	echo
#       do_diff
    else
        echo "Needpulse config"
        sudo rsync -av pulse/ $PULSE_CFG_DIR
    fi

    ## Restore directory on entry
    popd

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
    scope=

    systemctl $PA_SCOPE is-enabled "$service" > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "ENABLING $service"
        $SYSTEMCTL $PA_SCOPE enable "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem ENABLING $service"
        fi
    fi
    $SYSTEMCTL $PA_SCOPE --no-pager start "$service"
    if [ "$?" -ne 0 ] ; then
        echo "Problem starting $service"
    fi
}

# ===== function stop_service
function stop_service() {
    service="$1"
    systemctl $PA_SCOPE is-enabled "$service" > /dev/null 2>&1
    if [ $? -eq 0 ] ; then
        echo "DISABLING $service"
        $SYSTEMCTL $PA_SCOPE disable "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem DISABLING $service"
        fi
    else
        echo "Service: $service already disabled."
    fi
    $SYSTEMCTL $PA_SCOPE stop "$service"
    if [ "$?" -ne 0 ] ; then
        echo "Problem STOPPING $service"
    fi
}

#
# ===== function validate_callsign
# Validate callsign

function validate_callsign() {

    callsign="$1"
    sizecallstr=${#callsign}

    if (( sizecallstr > 6 )) || ((sizecallstr < 3 )) ; then
        echo "Invalid call sign: $callsign, length = $sizecallstr"
        return 1
    fi

    # Convert callsign to upper case
    CALLSIGN=$(echo "$callsign" | tr '[a-z]' '[A-Z]')
    return 0
}

# ===== function get_callsign

function get_callsign() {
    retcode=0
    # Check if call sign var has already been set
    if [ "$CALLSIGN" == "N0ONE" ] ; then
        echo "Enter call sign, followed by [enter]:"
        read -e callsign
    else
        echo "Error: call sign: $CALLSIGN"
    fi
    validate_callsign $callsign
    if [ $? -eq 0 ] ; then
        retcode=1
    else
        echo "Bad callsign found: $callsign"
    fi
    return $retcode
}

# ===== get_axports_callsign

function get_axports_callsign() {

    dbgecho "${FUNCNAME[0]} enter"

    retcode=1
    # get the first port line after the last comment
    #axports_line=$(tail -n3 $AXPORTS_FILE | grep -v "#" | grep -v "N0ONE" |  head -n 1)
    axports_line=$(tail -n3 $AXPORTS_FILE | grep -vE "^#|N0ONE" |  head -n 1)

    dbgecho "Using call sign from axports line: $axports_line"

    port=$(echo $axports_line | cut -d' ' -f1)
    # get rid of SSID
    callsign=$(echo $axports_line | tr -s '[[:space:]]' | cut -d' ' -f2 | cut -d '-' -f1)
    if [ ! -z $callsign ] ; then
        validate_callsign $callsign
        if [ $? -eq 0 ] ; then
            dbgecho "Using CALL SIGN: $CALLSIGN"
            retcode=0
        else
            echo "Bad callsign found: $callsign"
            CALLSIGN="N0ONE"
        fi
    fi
    return $retcode
}

# ===== function seq_backup
# Backup previous configuration file with a sequential name
# ie. never destroy a backup file
# arg 1 is path/root configuration file name

function seq_backup() {
    rootfname=$1
    today="$( date +"%Y%m%d" )"
    number=0
    # -- in printf statement: whatever follows should not be interpreted
    #    as a command line option to printf
    suffix="$( printf -- '-%02d' "$number" )"

    while test -e "$rootfname-$today$suffix.conf"; do
        (( ++number ))
        suffix="$( printf -- '-%02d' "$number" )"
    done

    fname="$rootfname-$today$suffix.conf"
    sudo mv ${rootfname}.conf $fname
}

# function comment_second_chan
# comment out entire x channel configuration in direwolf config file

function comment_chan() {
    CHN_NUM=$1
    # Add comment character
    $SED -i -e "/^CHANNEL $CHN_NUM/,/^$/ s/^\(^PTT GPIO.*\)/#\1/g" "$DIREWOLF_CFGFILE"
    $SED -i -e "/^CHANNEL $CHN_NUM/,/^$/ s/^\(^MODEM.*\)/#\1/g"    "$DIREWOLF_CFGFILE"
    $SED -i -e "/^CHANNEL $CHN_NUM/,/^$/ s/^\(^MYCALL.*\)/#\1/g"   "$DIREWOLF_CFGFILE"
    $SED -i -e "/CHANNEL $CHN_NUM/,/^$/ s/^\(^CHANNEL.*\)/#\1/g"   "$DIREWOLF_CFGFILE"
}

# ===== function remove_dw_virt
# Remove 2 virtual channels

function remove_dw_virt() {
    # To delete 5 lines after a pattern (including the line with the pattern):
    # sed -e '/pattern/,+5d' file.txt

    # Delete the 7 lines following ADEVICE0, excluding ADEVICE0 line
#    $SED -i -e "/^ADEVICE0/,+7d" $DIREWOLF_CFGFILE
    $SED -i -e "/^ADEVICE0/{n;N;N;N;N;N;N;ld}" $DIREWOLF_CFGFILE
    # Comment out remaining ADEVICE0 line
    $SED -i -e "s/^\(^ADEVICE0 .*\)/#\1/g"  $DIREWOLF_CFGFILE
    # Delete the 7 lines following ADEVICE1, excluding ADEVICE1 line
#    $SED -i -e "/^ADEVICE1/,+7d" $DIREWOLF_CFGFILE
    $SED -i -e "/^ADEVICE1/{n;N;N;N;N;N;N;d}" $DIREWOLF_CFGFILE
    # Comment out remaining ADEVICE0 line
    $SED -i -e "s/^\(^ADEVICE1 .*\)/#\1/g"  $DIREWOLF_CFGFILE
}

# ===== function config_dw_virt
# Configure direwolf to:
#  - use 2 virtual channels on a single channel using a DRAWS hat

function config_dw_virt() {

    ## Get rid of previous dw_virt configuration
    dbgecho "${FUNCNAME[0]}: Remove previous dw_virt config"
    remove_dw_virt

    ## comment out second channel
    dbgecho "${FUNCNAME[0]}: Comment out channel 0,1"
    comment_chan 0
    comment_chan 1

    ## comment out any stray ACHANNELS or ARATE
    ## FIX may want to just delete these lines
    $SED -ie "s/^[^#]*ACHANNELS/#&/"  $DIREWOLF_CFGFILE
    $SED -ie "s/^[^#]*ARATE/#&/"  $DIREWOLF_CFGFILE
    ## Replace ADEVICE with ADEVICE0 & ADEVICE1
    ## Setup ADEVICE0 as 1200 baud channel

#ADEVICE0 draws-capture-left draws-playback-left\n\

#CHANNEL 0\n\
#MYCALL ${CALLSIGN}-1\n\
#MODEM 1200\n\
#PTT GPIO 12\n/\

    dbgecho "${FUNCNAME[0]} sed 1"
    dbgecho " "
    grep -iq "^ADEVICE " $DIREWOLF_CFGFILE
    if [ $? -ne 0 ] ; then
        $SED -i "0,/# ADEVICE .*/{s//#\n\
ADEVICE0 draws-capture-left draws-playback-left\n\
ACHANNELS 1\n\
ARATE 48000\n\
CHANNEL 0\n\
MYCALL ${CALLSIGN}-1\n\
MODEM 1200\n\
PTT GPIO $PTT_GPIO_CHAN0\n\
\n/}" $DIREWOLF_CFGFILE

    else
        $SED -ie "/^ADEVICE .*/s/^ADEVICE .*/ADEVICE0 draws-capture-left draws-playback-left\n\
ACHANNELS 1\n\
ARATE 48000\n\
CHANNEL 0\n\
MYCALL ${CALLSIGN}-1\n\
MODEM 1200\n\
PTT GPIO $PTT_GPIO_CHAN0\n/" $DIREWOLF_CFGFILE

    fi

#    $SED -i -e "0,/^PTT GPIO.*/ s/PTT GPIO.*/PTT GPIO 12/" $DIREWOLF_CFGFILE
#    $SED -i -e '/^ACHANNELS 2/ s/2/1/' $DIREWOLF_CFGFILE


if [ 1 -eq 1 ] ; then
    ## Setup ADEVICE1 as 9600 baud channel
    dbgecho "${FUNCNAME[0]} Comment out sed 2"

#    $SED -ie "0,/^PTT GPIO 12.*/a\
    $SED -ie "/ADEVICE1.*/s/.*ADEVICE1 .*/ADEVICE1 draws-capture-left-sub draws-playback-left-sub \n\
ACHANNELS 1\n\
ARATE 48000\n\
CHANNEL 0\n\
MYCALL ${CALLSIGN}-2\n\
MODEM 9600\n\
PTT GPIO $PTT_GPIO_CHAN0\n/" $DIREWOLF_CFGFILE
fi

}

# ===== function is_direwolf
# Determine if direwolf is running

function is_direwolf() {
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

# ===== function check_pa_systemd()

function check_pa_systemd() {
    echo
    pa_user=false
    pa_sys=false

    if [ -f /usr/lib/systemd/user/pulseaudio.service ] ; then
        pa_user=true
	PA_SCOPE="--user"
    fi
    if [ -f /etc/systemd/user/pulseaudio.service ] ; then
        pa_user=true
	PA_SCOPE="--user"
    fi

    if [ -f /etc/systemd/system/pulseaudio.service ] ; then
        pa_sys=true
    fi
    if [ -f /usr/lib/systemd/system/pulseaudio.service ] ; then
        pa_sys=true
    fi

    if [ $pa_user = "true" ] && [ $pa_sys = "true" ] ; then
        echo
        echo "$(tput setaf 1)$scriptname: configuration WARNING both pulseaudio systemd user & system files exist$(tput sgr0)"
	echo "Will disable system pulseaudio service file."
	echo
	$SYSTEMCTL stop pulseaudio
	$SYSTEMCTL disable pulseaudio
    fi
    if [ $pa_user = "false" ] && [ $pa_sys = "false" ] ; then
        echo "$scriptname: configuration error no pulseaudio systemd file exists"
	# Install pulse audio here
        # Copy pulseaudio systemd file from n7nix repo
        echo "Copy pulse audio systemd start service"
        sudo cp -u $HOME/n7nix/systemd/sysd/pulseaudio.service /etc/systemd/system
    fi
}


# ===== function pulseaudio_install
function pulseaudio_install() {

    packagename="pulseaudio"
    is_pkg_installed $packagename
    if [ $? -ne 0 ] ; then
        if [ $b_painstall = true ] ; then
	    echo
            echo "$echo $(tput setaf 6)$scriptname: No package found: Installing $packagename$(tput sgr0)"
	    echo
            sudo apt-get install -y -q $packagename

	else
            echo "$scriptname: No $packagename package found"
	fi
    else
        # Found package, will continue
        echo "$scriptname: Detected $packagename package."

	# check_split_chan_install will call config_pa
	check_split_chan_install
	# check if there is a systemd service file anywhere
	check_pa_systemd

        service="pulseaudio"
        if systemctl $PA_SCOPE is-active --quiet "$service" ; then
            echo "${FUNCNAME[0]}: Service: $service is already running"
        else
            echo "${FUNCNAME[0]}: starting service: $service"
            start_service $service
        fi
    fi

    # Check if pulseaudio is running
    is_pulseaudio
    retcode=$?
    if [ "$retcode" -eq 0 ] ; then
        echo " == ${FUNCNAME[0]}:Pulse Audio is running with pid: $pid"
	echo " pulseaudio sinks: "
        pactl list sinks | grep -A3 "Sink #"
    else
        echo "${FUNCNAME[0]}: Pulse Audio is NOT running"
    fi
    $SYSTEMCTL $PA_SCOPE restart pulseaudio.service
    return $retcode
}

# ===== function pulseaudio_status
function pulseaudio_status() {

    echo " == pulseaudio_status"

    packagename="pulseaudio"
    is_pkg_installed $packagename
    if [ $? -ne 0 ] ; then
        echo "$scriptname: No $packagename package found"
    else
        # Found package, will continue
        echo "$scriptname: Detected $packagename package."

	# check_split_chan_install will call config_pa
	split_chan_status
	# check if there is a systemd service file anywhere
	check_pa_systemd

        service="pulseaudio"
	if [ -z $PA_SCOPE ] ; then
	    scope="sys"
	else
	    scope="user"
	fi
        if systemctl $PA_SCOPE is-active --quiet "$service" ; then
            echo "${FUNCNAME[0]}: systemd service: $service is running with scope: $scope"
        fi
    fi

    # Check if pulseaudio is running
    is_pulseaudio
    retcode=$?
    if [ "$retcode" -eq 0 ] ; then
        echo " == ${FUNCNAME[0]}: Pulse Audio is running with pid: $pid"
	echo " pulseaudio sinks: "
        pactl list sinks | grep -A3 "Sink #"
    else
        echo "${FUNCNAME[0]}: Pulse Audio is NOT running"
    fi
    return $retcode
}

# ===== function pulseaudio_on

function pulseaudio_on() {

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
    ax25-restart
}

# ===== function pulseaudio_off

function pulseaudio_off() {

    service="pulseaudio"

    if systemctl $PA_SCOPE is-active --quiet "$service" ; then
        stop_service $service
    else
        echo "Service: $service is already stopped"
    fi

    config_dw_2chan

    # restart direwolf/ax.25
    ax25-restart
}



# ===== function config_usb_1chan
# Configure direwolf to:
#  - use only one direwolf channel for CM108 sound card

function config_usb_1chan() {

    dbgecho "${FUNCNAME[0]} enter"

    $SED -i -e "0,/^ADEVICE .*/ s/^ADEVICE .*/ADEVICE plughw:CARD=Device,DEV=0/"  $DIREWOLF_CFGFILE
    $SED -i -e '/^ACHANNELS 2/ s/2/1/' $DIREWOLF_CFGFILE
    $SED -i -e "0,/^PTT GPIO.*/ s/PTT GPIO.*/PTT CM108/" $DIREWOLF_CFGFILE
}

# ===== function config_drw_2chan
# Edit direwolf.conf to use both channels (channel 0 & 1) of a DRAWS HAT

function config_drw_2chan() {

    dbgecho "${FUNCNAME[0]} enter"

#   $SED -i -e "0,/^ADEVICE .*/ s/^ADEVICE .*/ADEVICE draws-capture-$CONNECTOR draws-playback-$CONNECTOR/"  $DIREWOLF_CFGFILE
    $SED -i -e "0,/^ADEVICE .*/ s/^ADEVICE .*/ADEVICE plughw:CARD=udrc,DEV=0 plughw:CARD=udrc,DEV=0/"  $DIREWOLF_CFGFILE
    $SED -i -e '/^ACHANNELS 1/ s/1/2/' $DIREWOLF_CFGFILE

    # Assume direwolf config was previously set up for 2 channels
    $SED -i -e "0,/^PTT GPIO.*/ s/PTT GPIO.*/PTT GPIO $PTT_GPIO_CHAN0/" $DIREWOLF_CFGFILE
    dbgecho "${FUNCNAME[0]} exit"
}

parse_direwolf_config() {

    # Check if direwolf is running
    is_direwolf
    retcode=$?
    if [ "$retcode" -eq 0 ] ; then
        echo " == ${FUNCNAME[0]}: Direwolf is running with pid: $pid"
	echo " pulseaudio sinks: "
    else
        echo "${FUNCNAME[0]}: Direwolf is NOT running"
    fi

    # Determine if there is an "$scriptname" entry in direwolf config

    cfg_str=$(grep -i $scriptname $DIREWOLF_CFGFILE)

    if [ $? -ne 0 ] ; then
        echo "Not edited by $scriptname"
    else
	cfg_str=$(sed -e "s/^#//" <<< $cfg_str)
        echo "Current: $cfg_str"
    fi
    numchan=$(grep "^ACHANNELS" $DIREWOLF_CFGFILE | head -n 1 | cut -d' ' -f2)
    if [ ! -z $numchan ] ; then
        if [ $numchan -eq 1 ] ; then
            echo "Setup for single channel"
        else
            echo "Setup for DRAWS dual channel hat"
        fi
    else
        echo "ACHANNELS is NOT set"
    fi
    audiodev=$(grep "^ADEVICE" $DIREWOLF_CFGFILE | cut -d ' ' -f2)
    device_cnt=$(grep -c "^ADEVICE" $DIREWOLF_CFGFILE)
    echo "Audio device [$device_cnt]: $audiodev"
    echo " == PTT"
    grep -i "^PTT " $DIREWOLF_CFGFILE
}

# ===== function usage
function usage() {
   echo "Usage: $scriptname [-C <callsign>][-c <channel_number>][-D <device_name>][-d][-s][-h]" >&2
   echo " Default to configuring a USB device on channel 0"
   echo "   -C <call sign>    Specify a HAM call sign"
   echo "   -c <chan number>  Channel number: 0, 1, b for both, v for virtual"
   echo "   -D <device>       Device type: drw or usb, default usb"
   echo "   -d                Set debug flag"
   echo "   -s                Display direwolf config status"
   echo "   -h                no arg, display this message"
   echo
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

REPO_DIR="/home/$USER/dev/github"
SPLIT_DIR="$REPO_DIR/split-channels"

while [[ $# -gt 0 ]] ; do
key="$1"

case $key in

   -s|--status)
       parse_direwolf_config
       pulseaudio_status
       exit 1
   ;;
   -C|--callsign)
      CALLSIGN=$2
      shift # past argument
      validate_callsign $CALLSIGN
    if [ $? -eq 0 ] ; then
        dbgecho "Using CALL SIGN: $CALLSIGN"
        retcode=1
    else
        echo "Bad callsign found: $CALLSIGN"
        exit 1
    fi
   ;;
   -c|--chan)
     CHAN_NUM="$2"
     shift # past argument
     if [ "$CHAN_NUM" != "0" ] && [ "$CHAN_NUM" != "1" ] && [ "$CHAN_NUM" != "v" ] && [ "$CHAN_NUM" != "b" ] ; then
         echo "Invalid channel number: $CHAN_NUM, can be 0, 1, b or v, default to 0"
	 CHAN_NUM="0"
     else
         dbgecho "Channel number set to $CHAN_NUM"
     fi
   ;;
   -D|--device)
      DEVICE_TYPE="$2"
      shift # past argument
      if [ "$DEVICE_TYPE" != "usb" ] && [ "$DEVICE_TYPE" != "drw" ] ; then
          echo "Invalid device type: $DEVICE_TYPE, can be either 'usb' or 'drw', default to usb device"
	  DEVICE_TYPE="usb"
      else
          dbgecho "Device Type set to $DEVICE_TYPE"
      fi
   ;;
   -d|--debug)
      DEBUG=1
      echo "Debug mode on"
   ;;
   -h|--help|?)
      usage
      exit 0
   ;;
   *)
      # unknown option
      echo "Unknow option: $key"
      usage
      exit 1
   ;;
esac
shift # past argument or value
done

# Add the following string to initial comment section
keystring="# Configured with ${scriptname}"

# Last line in an UNedited initial comment section
search_str="# Command parameters are"

#
# Determine how direwolf is currently configured.
# - look for the $keystring
#
cur_keystr=$(grep -i "$keystring" $DIREWOLF_CFGFILE)
retcode=$?
if [ $retcode -ne 0 ] ; then
    echo "Direwolf config file has not been configured with this script."
else
    echo "DEBUG: $cur_keystr"
    cur_chan_num=$(echo $cur_keystr | cut -d':' -f2 | cut -d ',' -f1)
    # Remove preceding white space & any non printable characters
    cur_chan_num=$(echo ${cur_chan_num##+([[:space:]])})

    cur_device_type=$(echo $cur_keystr | cut -d':' -f3)
    cur_device_type=$(echo ${cur_device_type##+([[:space:]])})


    echo "Direwolf current configured: Channel: -${cur_chan_num}-, Device -${cur_device_type}-"
fi


# Update string in direwolf file that indicates it's been edited by this
# script.
# Determine if there is already an "$scriptname" entry
# retcode variable set from previous grep
if [ $retcode -ne 0 ] ; then
    # echo "DEBUG: First sed"
    # Insert string after first blank line after $search_str
    $SED -i "/${search_str}/,/^$/s/^$/#\n\
${keystring}, Channel: $CHAN_NUM, Device: ${DEVICE_TYPE} on $(date)\
\n/" $DIREWOLF_CFGFILE
else
    # Replace $keystring line with new $keystring line
    $SED -i -e "0,/${keystring}.*/ s/# Configured with .*/\
${keystring}, Channel: $CHAN_NUM, Device: ${DEVICE_TYPE} on $(date)/" $DIREWOLF_CFGFILE
    retcode=$?
    echo "DEBUG: Second sed: chan: $CHAN_NUM, dev: $DEVICE_TYPE, ret: $retcode"
fi

# echo "DEBUG1: Check difference of direwolf config to a reference file"
# diff direwolf.conf /etc

dbgecho "Get a callsign: $CALLSIGN"
# Try to parse callsign from /etc/ax25/axports file
if [ $CALLSIGN = "N0ONE" ] ; then
    ## Get a valid callsign from axports file
    get_axports_callsign
    retcode="$?"

    dbgecho "retcode: $retcode from get_axports_callsign"

    if [ $retcode -ne 0 ] ; then

        ## Get a callsign from command line
        echo "prompt for a callsign:"
        while get_callsign ; do
            retcode=$?
            echo "Input error ($retcode), try again"
        done
    fi
fi

dbgecho "CALLSIGN set to: $CALLSIGN"

if [ $CHAN_NUM = "v" ] ; then
    b_painstall=true
    pulseaudio_install
    config_dw_virt
    # Do the following to get direwolf to read the new config
    ax25-restart
else
    case $DEVICE_TYPE in
        usb)
            config_usb_1chan
        ;;
        drw)
            dbgecho "calling config_drw_2chan"
            config_drw_2chan
        ;;
        *)
            echo "Invalid device type: $DEVICE_TYPE"
       ;;
    esac
fi

# echo "DEBUG2: Check difference of direwolf config to a reference file"
# diff -wBb /etc/direwolf.conf $HOME/tmp/dire/direwolf.conf

# Add to groups
#sudo usermod -a -G pulse pi
#sudo usermod -a -G pulse root
exit 0
