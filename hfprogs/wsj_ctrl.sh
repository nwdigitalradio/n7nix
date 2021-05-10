#!/bin/bash
#
# wsj_ctrl.sh

#
# start, stop & show status for  rigctld-wsjtx process
#
# Creates one systemd unit file
# rigctld-wsjtx.service
DEBUG=

BIN="/usr/bin"
LBIN="/usr/local/bin"
LOCAL_BIN="/home/pi/bin"
scriptname="$(basename "$0")"

rigservice_name="rigctld-wsjtx"

SYSTEMD_DIR="/etc/systemd/system"
FORCE_UPDATE=
DISPLAY_PARAMETERS=false

rigctrl_device="/dev/ttyUSB0"

# names of supported radios
RADIOLIST="ic706 ic7000 ic7300 k2 k3 kx2 kx3"

# Rig numbers are from rigctl-wsjtx -l
declare -A radio_ic706=( [rigname]="IC-706" [rignum]=3011 [audioname]=udrc [samplerate]=48000 [baudrate]=4800 [pttctrl]="GPIO" [catctrl]="" [rigctrl]="-p 12" [alsa_lodriver]="-6.0" [alsa_pcm]="-26.5" )
declare -A radio_ic7000=( [rigname]="IC-7000" [rignum]=3060 [audioname]=udrc [samplerate]=48000 [baudrate]=19200 [pttctrl]="GPIO=12" [catctrl]="" [rigctrl]="" [alsa_lodriver]="-6.0" [alsa_pcm]="-16.5" )
declare -A radio_ic7300=( [rigname]="IC-7300" [rignum]=3073 [audioname]=CODEC [samplerate]=48000 [baudrate]=19200 [pttctrl]="/dev/ttyUSB0" [catctrl]="-c /dev/ttyUSB0" [rigctrl]="-p /dev/ttyUSB0 -P RTS" [alsa_lodriver]="-6.0" [alsa_pcm]="-16.5" )
declare -A radio_k2=( [rigname]="K2" [rignum]=2021 [audioname]=udrc [samplerate]=48000 [baudrate]=19200 [pttctrl]="GPIO=12" [catctrl]="" [rigctrl]="" [alsa_lodriver]="0.0" [alsa_pcm]="0.0" )
declare -A radio_k3=( [rigname]="K3" [rignum]=2029 [audioname]=udrc [samplerate]=48000 [baudrate]=19200 [pttctrl]="GPIO=12" [catctrl]="" [rigctrl]="" [alsa_lodriver]="0.0" [alsa_pcm]="0.0" )
declare -A radio_kx2=( [rigname]="KX2" [rignum]=2044 [audioname]=udrc [samplerate]=48000 [baudrate]=19200 [pttctrl]="GPIO=12" [catctrl]="" [rigctrl]="" [alsa_lodriver]="0.0" [alsa_pcm]="0.0" )
declare -A radio_kx3=( [rigname]="KX3" [rignum]=2045 [audioname]=udrc [samplerate]=48000 [baudrate]=19200 [pttctrl]="GPIO=12" [catctrl]="" [rigctrl]="" [alsa_lodriver]="0.0" [alsa_pcm]="0.0" )

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function name_check
# Verify that the supplied radio name is in the supported list
function name_check() {
    retcode=1
    namecheck=$1

    for radio_name in ${RADIOLIST} ; do
        if [ "$radio_name" = "$namecheck" ] ; then
            return 0
        fi
    done
    return $retcode
}

# ===== function desktop_pat_file
# Use a heredoc to build the Desktop/pat file

function desktop_pat_file() {
    # If running as root do NOT create any user related files
    if [[ $EUID != 0 ]] ; then
        # Set up desktop icon for PAT
        filename="$HOME/Desktop/pat.desktop"
        if [ ! -e $filename ] || [ ! -z "$FORCE_UPDATE" ] ; then

            tee $filename > /dev/null << EOT
[Desktop Entry]
Name=PAT
Type=Link
URL=http://localhost:8080
Icon=/usr/share/icons/PiXflat/32x32/apps/mail.png
EOT
        fi
    else
        echo
        echo " Running as root so PAT desktop file not created"
    fi
}

# ===== function desktop_waterfall_file
# Use a heredoc to build the Desktop/ardop-gui file

function desktop_waterfall_file() {

    # If running as root do NOT create any user related files
    if [[ $EUID != 0 ]] ; then
        # Set up desktop icon for piARDOP_GUI
        filename="$HOME/Desktop/ardop-gui.desktop"
        if [ ! -e $filename ] || [ ! -z "$FORCE_UPDATE" ] ; then

            tee $filename > /dev/null << EOT
[Desktop Entry]
Name=ARDOP-waterfall
Comment=Startup waterfall for ardop
Exec=/home/pi/bin/piARDOP_GUI
Type=Application
# Some random icon
Icon=/usr/lib/python3/dist-packages/thonny/plugins/pi/res/zoom.png
Terminal=False
Categories=Network;HAM Radio;
EOT
        fi
    else
        echo
        echo " Running as root so ARDOP desktop file not created"
    fi
}

# ===== function asoundfile
# Use a heredoc to build the .asoundrc file

function asoundfile() {

    audio_device="$1"
    # Determine correct audio card number for .asoundrc file
    CARDNO=$(aplay -l | grep -i $audio_device)
    if [ ! -z "$CARDNO" ] ; then
        # echo "asoundrc_file_check: udrc card number line: $CARDNO"
        CARDNO=$(echo $CARDNO | cut -d ' ' -f2 | cut -d':' -f1)
    else
        echo "Problem finding audio device ($audio_device) card number"
        CARDNO=1
    fi

    sudo tee $HOME/.asoundrc > /dev/null << EOT
pcm.ARDOP {
        type rate
        slave {
        pcm "hw:${CARDNO},0"
        rate ${radio[samplerate]}
        }
}
EOT
}

# ===== function unitfile_rigctld
# For IC-7300
# ExecStart=/usr/bin/rigctld-wsjtx -m 373 -r /dev/ttyUSB0 -p /dev/ttyUSB0 -P RTS -s 19200
# Use a heredoc to build the rigctld-wsjtx.service file

function unitfile_rigctld() {

    echo "DEBUG: creating $rigservice_name unit file for radio: ${radio[rigname]}"

    sudo tee /etc/systemd/system/$rigservice_name.service > /dev/null << EOT
[Unit]
Description=$rigservice_name
#Before=pat
After=remote-fs.target
After=syslog.target

[Service]

Restart=on-failure
RestartSec=5s

ExecStart=/usr/bin/$rigservice_name -m ${radio[rignum]} -r $rigctrl_device -s ${radio[baudrate]} -P ${radio[pttctrl]} ${radio[rigctrl]}
WorkingDirectory=/home/pi/
StandardOutput=inherit
StandardError=inherit
User=pi

[Install]
WantedBy=multi-user.target
#WantedBy=pat
EOT
}

# ===== function unitfile_ardop
# Use a heredoc to build the ardop.service file
#
# ./piardopc 8515 pcm.ARDOP pcm.ARDOP -c /dev/ttyUSB0 -p /dev/ttyUSB
# From piardopc documentation
# -p device or --ptt device         Device to use for PTT control using RTS or GPIO Pin (Raspbery Pi only)
# -c device or --cat device         Device to use for CAT Control
# -k string or --keystring string   String (In HEX) to send to the radio to key PTT
# -u string or --unkeystring string String (In HEX) to send to the radio to unkeykey PTT

function unitfile_ardop() {
    echo "DEBUG: creating ardop unit file for radio: ${radio[rigname]}"

    sudo tee /etc/systemd/system/ardop.service > /dev/null << EOT
[Unit]
Description=ardopc - ARDOP softmodem for pi
After=network.target sound.target

[Service]
User=pi
WorkingDirectory=/home/pi/
ExecStart=/bin/sh -c "/home/pi/bin/piardopc 8515 pcm.ARDOP pcm.ARDOP ${radio[catctrl]} -p ${radio[pttctrl]}"
#ExecStart=/bin/sh -c "/home/pi/bin/piardopc 8515 plughw:1,0 plughw:1,0 ${radio[catctrl]} -p ${radio[pttctrl]} "
Restart=no

[Install]
WantedBy=multi-user.target
EOT
}

# ===== function unitfile_pat
# Use a heredoc to build the pat.service file

function unitfile_pat() {
sudo tee /etc/systemd/system/pat.service > /dev/null << EOT
[Unit]
Description=pat
#Before=network.target
Requires=rigctld
#Wants=rigctld

[Service]
User=pi
ExecStart=/usr/bin/pat --listen="ardop" http
WorkingDirectory=/home/pi/
StandardOutput=inherit
StandardError=inherit
Restart=no

[Install]
WantedBy=multi-user.target
EOT
}

# ===== function unitfile_exists
# A more general way to determine existence of a systemd service file
function unitfile_exists() {
  [ $(systemctl list-unit-files "${1}*" | wc -l) -gt 3 ]
}

# ===== function status_service

function status_service() {
    service="$1"
    IS_ENABLED="ENABLED"
    IS_RUNNING="RUNNING"
    # echo "Checking service: $service"
    systemctl is-enabled "$service" > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        IS_ENABLED="NOT ENABLED"
    fi
    systemctl is-active "$service" > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        IS_RUNNING="NOT RUNNING"
    fi
}

# ===== function status_all_processes
function status_all_processes() {
#    for process in "$rigservice_name" "piardopc" "piARDOP_GUI" "pat" ; do
    for process in "$rigservice_name" ; do

        pid_pat="$(pidof $process)"
        ret=$?
        # Display process: name, pid, arguments
        if [ "$ret" -eq 0 ] ; then
            args=$(ps aux | grep "$pid_pat " | grep -v "grep" | head -n 1 | tr -s '[[:space:]]' | sed -n "s/.*$process//p")
            echo "proc $process: $ret, pid: $pid_pat, args: $args"
        else
            echo "proc $process: $ret, NOT running"
        fi
    done
}

# ===== function status_all_services

function status_all_services() {
#    for service in "$rigservice_name" "ardop" "pat" ; do
    for service in "$rigservice_name" ; do
        status_service
    done
}

# ===== function start_service

function start_service() {
    service="$1"

    systemctl is-enabled "$service" > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "ENABLING $service"
        $SYSTEMCTL enable "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem ENABLING $service"
        fi
    fi
    systemctl is-active "$service" > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "Starting service: $service"
        $SYSTEMCTL --no-pager start "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem starting $service"
        fi
    else
        echo "Service: $service already running."
    fi
}

# ===== function stop_service

function stop_service() {
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
    echo "Service: $service now stopped."
}

# ===== function check_service

function check_service() {

    service="$1"
    if $SYSTEMCTL is-active --quiet "$service" ; then
        echo "Stopping service: $service"
        stop_service $service
    else
        dbgecho "Service: $service is already stopped"
    fi
}

# ===== function kill_process
function kill_process() {
    kill_flag=$1
    dbgecho
    dbgecho "DEBUG: kill_process: kill_flag $kill_flag"
    dbgecho

#    for process in "$rigservice_name" "piardopc" "pat" ; do
    for process in "$rigservice_name" ; do

        pid_pat="$(pidof $process)"
        ret=$?
        # Display process: name, pid, arguments
        if [ "$ret" -eq 0 ] ; then
            args=$(ps aux | grep -i $pid_pat | grep -v "grep" | head -n 1 | tr -s '[[:space:]]' | sed -n "s/.*$process//p")
            echo "proc $process: $ret, pid: $pid_pat, args: $args"
        fi

        # Stop systemd services
        service="$process"
        if [ "$process" = "piardopc" ] ; then
            service="ardop"
        fi

        if $SYSTEMCTL is-active --quiet "$service" ; then
            stop_service $service
        else
            # kill ardop process
            if [ "$ret" -eq 0 ] && [ "$kill_flag" = "true" ] ; then
                echo "$process running with pid: $pid_pat, killing"
                kill $pid_pat
            fi
        fi
    done
}

# ===== function audio_device_check

function audio_device_check() {

    audio_device=$1
    if [ -z $audio_device ] ; then
        echo "Need to pass audio device name to audio_device_check()"
        return
    fi

    echo -n "  == audio device $audio_device check: "
    if [ -e "/proc/asound/$audio_device/pcm0c/sub0/status" ] ; then
        grep -i "state:\|closed" "/proc/asound/$audio_device/pcm0c/sub0/status"
    else
        echo "device status file does NOT exist"
    fi
}

# ===== function process_check

function process_check() {
    kill_flag=
    if [ "$1" -eq 1 ] ; then
        kill_flag=true
        echo "kill flag set"
    fi

    auddev="udrc"
    if [ "$radio_name" = "IC-7300" ] ; then
         # I think this should be CODEC
#        auddev="/dev/ttyUSB0"
         auddev="CODEC"
    fi

    audio_device_check $auddev
#    asoundrc_file_check $auddev
}

# ===== function unitfile_update
# systemd unit file copy

function unitfile_update() {

    echo " == unit file update"

#    for unit_file in "$rigservice_name" "ardop" "pat" ; do
    for unit_file in "$rigservice_name" ; do
        case $unit_file in
            rigctld-wsjtx)
                unitfile_rigctld
            ;;
            ardop)
                unitfile_ardop
            ;;
            pat)
                unitfile_pat
            ;;
            *)
                echo "Do not recognize this unit file name: $unit_file"
                exit 1
            ;;
        esac
    done

    $SYSTEMCTL daemon-reload
}

# ===== function systemd unit file check
# systemd unit file exists check

function unitfile_check() {

    echo " == $rigservice_name systemctl unit file check"
    reload_flag=0

#    for file in "$rigservice_name" "ardop" "pat" ; do
    for file in "$rigservice_name"  ; do
        if [ ! -e "$SYSTEMD_DIR/${file}.service" ] ; then
            reload_flag=1
            echo "Systemd unit file: $SYSTEMD_DIR/${file}.service NOT found."
        else
            systemctl status $file >/dev/null 2>&1
            status=$?
            echo "$(tput setaf 4)Service: $file, status: $status$(tput sgr0)"
        fi
    done

    if [ "$reload_flag" -eq 0 ] && [ -z "$FORCE_UPDATE" ] ; then
        echo "Systemd service files found"
    else
        echo "Creating systemd service files."
        unitfile_update
        reload_flag=1
    fi

    #echo "DEBUG: reload_flag from unitfile_check: $reload_flag"

    # Check if a daemon-reload is required
    if [ "$reload_flag" -eq 1 ] ; then
        echo " systemctl daemon-reload"
        $SYSTEMCTL daemon-reload
    fi
}

# ===== function process_status

function process_status() {

    unitfile_check

    echo " == rigctld-wsjtx process check"
    status_all_services
    status_all_processes

    auddev="udrc"
    if [ "$radio_name" = "IC-7300" ] ; then
         # I think this should be CODEC
#        auddev="/dev/ttyUSB0"
         auddev="CODEC"
    fi
    audio_device_check $auddev
}

# ===== function is_pulseaudio
# Determine if pulse audio is running

function is_pulseaudio() {
    pid=$(pidof pulseaudio)
    retcode="$?"
    return $retcode
}

# ===== function check for an integer

function is_num() {
    local chk=${1#[+-]};
    [ "$chk" ] && [ -z "${chk//[0-9]}" ]
}

# ===== function which radio is configured

function which_radio() {

    radio_name=
    service_file="/etc/systemd/system/$rigservice_name.service"
    if [ -e "$service_file" ] ; then
        radionum=$(grep "$rigservice_name -m" $service_file | cut -d' ' -f3)
        if is_num $radionum ; then
            dbgecho "radio number ok: $radionum"
            for array in $RADIOLIST ; do
               arrayname="radio_${array}"
               declare -n radarray=$arrayname
               #debug
               # echo "name ${radarray[rigname]}, number: ${radarray[rignum]}"
               if [ "${radarray[rignum]}" -eq "$radionum" ] ; then
                   radio_name="${radarray[rigname]}"
                   break;
               fi
            done
        else
            echo "Check $rigservice_name unit file, not configured properly"
        fi
    else
        echo "$rigservice_name not configured"
    fi
}

# ===== function radio_name_verify
# return 0 if radio name on command line matches radio name in service
# file

function radio_name_verify() {
    retcode=0

    # radio_name var is set by which_radio from rigctld-wsjtx service file
    which_radio

    # upper to lower case
    xradio_name=$(echo "$radio_name" | tr '[A-Z]' '[a-z]')
    # get rid of dash
    xradio_name=${xradio_name//[-]/}
    xradioname="$(echo $radioname| cut -f2 -d'_')"

    dbgecho "DEBUG: $xradio_name $xradioname"

    if [ -z "$radio_name" ] ; then
	recode=1
        echo " *** rigctld-wsjtx NOT CONFIGURED."

    elif [ "$xradio_name" != "$xradioname" ] ;then
	recode=1

        echo
        echo "$(tput setaf 1) Configured radio $radio_name DOES NOT MATCH requested radio $radioname$(tput setaf 7)"
	echo
        # Check if in DEBUG mode or just displaying parameters
        if [ ! -z $DEBUG  ] && [ "$DISPLAY_PARAMETERS" = "false" ] ; then
            echo "DEBUG: $DEBUG, DISPLAY: $DISPLAY_PARAMETERS"
	    exit 1
        fi
    else
        dbgecho " configured rig: $radio_name matches requested rig $radioname"
    fi
}

function radio_name_verify_silent() {
    retcode=0

    # radio_name var is set by which_radio from rigctld-wsjtx service file
    which_radio

    # upper to lower case
    xradio_name=$(echo "$radio_name" | tr '[A-Z]' '[a-z]')
    # get rid of dash
    xradio_name=${xradio_name//[-]/}
    xradioname="$(echo $radioname| cut -f2 -d'_')"

    dbgecho "DEBUG: $xradio_name $xradioname"

    if [ -z "$radio_name" ] ; then
	recode=1
        dbgecho " *** rigctld-wsjtx NOT CONFIGURED."

    elif [ "$xradio_name" != "$xradioname" ] ;then
	recode=1

        dbgecho "$(tput setaf 1) Configured radio $radio_name DOES NOT MATCH requested radio $radioname$(tput setaf 7)"

        # Check if in DEBUG mode or just displaying parameters
        if [ ! -z $DEBUG  ] && [ "$DISPLAY_PARAMETERS" = "false" ] ; then
            echo "DEBUG: $DEBUG, DISPLAY: $DISPLAY_PARAMETERS"
	    exit 1
        fi
    else
        dbgecho " configured rig: $radio_name matches requested rig $radioname"
    fi
}

# ===== function asoundrc_file_check
function asoundrc_file_check() {

    audio_device="$1"

    if [[ $EUID != 0 ]] ; then
        cfgfile="$HOME/.asoundrc"
        if [ ! -e "$cfgfile" ] || [ "$FORCE_UPDATE" = "true" ] ; then
            echo "File: $cfgfile does not exist, creating"
            # create asound file in user home directory
            asoundfile $audio_device
        else
            grep -i "pcm.ARDOP" $cfgfile > /dev/null 2>&1
            if [ $? -ne 0 ] ; then
                echo "asoundrc_file_check: No ARDOP entry in $cfgfile"
            else
                echo "asoundrc_file_check: Found ARDOP entry in $cfgfile"
                CARDNO=$(aplay -l | grep -i $audio_device)

                if [ ! -z "$CARDNO" ] ; then
#                    echo "asoundrc_file_check: udrc card number line: $CARDNO"
                    CARDNO=$(echo $CARDNO | cut -d ' ' -f2 | cut -d':' -f1)
#                    echo "asoundrc_file_check: udrc is sound card #$CARDNO"
                    asound_cardno=$(grep -i pcm $cfgfile | tail -n 1 | cut -d':' -f2 | cut -d',' -f1)
                    if [ $CARDNO -ne $asound_cardno ] ; then
                        echo
                        echo " asoundrc_file_check: asound cfg device ($asound_cardno) does NOT match aplay device ($CARDNO)"
                        echo
                    else
                        echo "asoundrc_file_check: asound cfg device match: sound card number: $CARDNO"
                    fi
                else
                    echo "asoundrc_file_check: No sound card ($audio_device) found."
                fi
                sample_rate=$(grep -m2 -i rate ~/.asoundrc | tail -n1 | tr -s '[[:space:]] ' | cut -f3 -d' ')
                echo "asoundrc_file_check: sample rate: $sample_rate"

            fi
        fi
    else
        # If running as root do NOT create any user related files
        echo
        echo " Running as root so .asoundrc file not checked"
    fi
}


# ==== ardop_file_status
# Verify ardop programs are installed

function ardop_file_status() {

    is_pulseaudio
    if [ "$?" -eq 0 ] ; then
        echo "== Pulse Audio is running with pid: $pid"
    else
        echo "Pulse Audio is NOT running"
    fi

    auddev="udrc"
    if [ "$radio_name" = "IC-7300" ] ; then
         # I think this should be CODEC
#        auddev="/dev/ttyUSB0"
         auddev="CODEC"
    fi

    # Check for .asoundrc & asound.conf ALSA configuration files
    # Verify virtual sound device ARDOP
#    asoundrc_file_check $auddev

    # Verify config file to define virtual devices for split channel operation
    cfgfile="/etc/asound.conf"
    if [ ! -e "$cfgfile" ] ; then
        echo "File: $cfgfile does not exist"
    else
        echo "Found file: $cfgfile for split channel operation"
    fi

    PROGLIST="piARDOP_GUI piardop2 piardopc"

    echo " == Ardop Verify required programs"

    for prog_name in `echo ${PROGLIST}` ; do
        type -P $prog_name &> /dev/null
        retcode="$?"
        if [ "$retcode" -ne 0 ] ; then
            echo "$scriptname: Need to Install $prog_name"
            NEEDPKG_FLAG=true
        else
            # Get last word of filename, break on under bar, only look at first 3 characters
            lastword=$(grep -oE '[^_]+$' <<< $prog_name | cut -c1-3)
            if [ "$lastword" != "GUI" ] ; then
                echo "Found program: $prog_name, $($prog_name -h | head -n 1)"
            else
                echo "Found program: $prog_name"
            fi
        fi
    done

    prog_name="arim"
    type -P $prog_name &> /dev/null
    if [ $? -ne 0 ] ; then
        echo "$scriptname: Need to Install $prog_name"
        NEEDPKG_FLAG=true
    else
        echo "Found program: $prog_name, version: $($prog_name -v | head -n 1)"
    fi
    prog_name="pat"
    type -P $prog_name &> /dev/null
    if [ $? -ne 0 ] ; then
        echo "$scriptname: Need to Install $prog_name"
        NEEDPKG_FLAG=true
    else
        echo "Found program: $prog_name, version: $($prog_name version)"
    fi
}

# ==== function display radio parameters stored in associative array

function display_parameters() {
    echo
    echo "== Dump radio parameters for radio: $radioname"
    if [ ! -z $DEBUG  ] ; then
        echo
        keycnt=0
        for key in "${!radio[@]}"; do
            echo -n "$key -> ${radio[$key]}, "
            ((keycnt++))
            if [ $keycnt -ge 3 ] ; then
                echo
                keycnt=0
            fi
        done
    fi

    printf "rig number: %s, baud rate: %s, audio device: %s, alsa sample rate: %s, ptt: %s, cat: %s, alsa pcm: %s\n" ${radio[rignum]} ${radio[baudrate]} ${radio[audioname]} ${radio[samplerate]} ${radio[pttctrl]} "$catctrl" "${radio[alsa_pcm]}"
}

# ==== function display arguments used by this script

usage () {
	(
	echo "Usage: $scriptname [-a <name>][-f][-d][-h][status][stop][start]"
        echo "                  No args will show status of $rigservice_name"
        echo "  -a <radio name> specify radio name (ic706 ic7000 ic7300 k2 k3 kx2 kx3)"
        echo "  -f | --force    Update all systemd unit files"
        echo "  -p              Print parameters for a particular radio name"
        echo "  -d              Set DEBUG flag"
	echo
        echo "                  args with dashes must come before following arguments"
	echo
        echo "  start           start required $rigservice_name process"
        echo "  stop            stop all $rigservice_name process"
        echo "  status          display status of all $rigservice_name process"
        echo "  -h              Display this message."
        echo
	) 1>&2
	exit 1
}

# ===== main

# Check if running as root
if [[ $EUID != 0 ]] ; then
   SYSTEMCTL="sudo systemctl "
else
   SYSTEMCTL="systemctl"
fi


# draws manager collides with pat http

check_service "draws-manager"

# For now assume NOT running in split_channel mode and
#  shut down direwolf
check_service "direwolf"

if [[ $# -eq 0 ]] ; then
    APP_ARG="status"
fi

# default radio name
radioname="radio_ic706"
declare -n radio=$radioname

while [[ $# -gt 0 ]] ; do
APP_ARG="$1"

case $APP_ARG in
    -a)
        # specify radio name
        radioname=$2

        shift  # past argument

        name_check $radioname
        if [ $? -eq 1 ] ; then
            echo "Radio: $radioname NOT supported"
            exit
        fi
        radioname="radio_${radioname}"
        declare -n radio=$radioname
        echo "Setting radio name to: $radioname, rig name: ${radio[rigname]}"

        #echo "DEBUG: radio name: $radioname, radio: $radio_name"
        #printf "rig ctrl baud rate: %s\n" ${radio[baudrate]}
        #echo
        if [ ! -z "$DEBUG" ] ; then
            catctrl=${radio[catctrl]}

            if [ -z "$catctrl" ] ; then catctrl="rigctl" ; fi
            display_parameters
        fi
    ;;
    -p)
        DISPLAY_PARAMETERS=true
   ;;
    -f|--force)
        FORCE_UPDATE=true
        echo "Force update mode on"
   ;;
    -d|--debug)
        DEBUG=1
        echo "Debug mode on"
   ;;
    stop)
        echo "Kill $rigservice_name process"
        # temporary until everything is started with systemd
        kill_process true
    ;;
    start)

#        if [ "$FORCE_UPDATE" = "true" ] ; then
         radio_name_verify_silent
	 if [ "$?" -ne 0 ] ; then
	    echo "DEBUG: Updating systemd unitfiles to match $radioname"
            unitfile_update
            which_radio
	else
            # Check FORCE_UPDATE flag to refresh systemd service files.
            unitfile_check
        fi

        for service in "$rigservice_name" ; do
            start_service $service
        done
        if [ 1 -eq 0 ] ; then
            # Will create desktop icon start up file if:
            #  Not running as root and (Desktop file does not exist or FORCE_UPDATE is true)
            desktop_waterfall_file
            desktop_pat_file
	fi

        systemctl status $rigservice_name >/dev/null 2>&1
        status=$?
        echo "$(tput setaf 4)Service: $file, status: $status$(tput sgr0)"
        dbgecho "Finished  $rigservice_name $APP_ARG"
        exit 0
    ;;
    status)
        radio_name_verify

        echo
        echo " == Status for configured rig: $radio_name"
#        ardop_file_status
        process_status
        dbgecho "Finished  $rigservice_name $APP_ARG"
        exit 0
    ;;
    -h|--help|-?)
        usage
        exit 0
   ;;
   *)
        echo "Unrecognized command line argument: $APP_ARG"
        usage
        exit 0
   ;;

esac

shift # past argument
done

# make variable radio an alias for radioname
declare -n radio=$radioname

radio_name_verify

if [ $DISPLAY_PARAMETERS = true ] ; then
    display_parameters
    exit 0
fi

echo
echo " == Status for configured rig: $radio_name"

process_check 0

if [ 1 -eq 0 ] ; then
    # Will create desktop icon start up file if:
    #  Not running as root and (Desktop file does not exist or FORCE_UPDATE is true)
    desktop_waterfall_file
    desktop_pat_file
fi

# Check FORCE_UPDATE flag to refresh systemd service files.
unitfile_check

echo " == rigctld-wsjtx process check"
status_all_processes

dbgecho "Finished $rigservice_name $APP_ARG"
