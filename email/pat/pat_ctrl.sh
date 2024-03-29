#!/bin/bash
#

scriptname="`basename $0`"
PAT_CONFIG_FILE="${HOME}/.config/pat/config.json"
AXPORTS_FILE="/etc/ax25/axports"

SYSTEMCTL="systemctl"

ONLY_PAT_LISTEN=1

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function start_service

function start_service() {

    service="$1"
    echo "Starting service: $service"
    systemctl is-enabled "$service" > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "ENABLING $service"
        $SYSTEMCTL enable "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem ENABLING $service"
        fi
    else
        echo "Service: $service already ENabled."
    fi

    if systemctl is-active --quiet "$service" ; then
        echo "Starting service but service: $service is already running"
    else
        $SYSTEMCTL --no-pager start "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem starting $service"
        fi
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
    else
        echo "Service: $service now stopped."
    fi
}

# ===== function status_port
# Check if network port is already in-use

function status_port() {

    if [ -z "$1" ] ; then
        service="none specified"
    else
        service="$1"
    fi

    chk_port=$(sudo lsof -i -P -n | grep LISTEN | grep 8080)
    if [ $? -eq 0 ] ; then
        port_cmd=$(echo "$chk_port" | cut -f1 -d ' ')
        echo " == Port 8080 in use by: $port_cmd"
#	echo "Service $service will NOT start"
    else
        echo "Port 8080 NOT in use"
    fi
}


# ===== function unitfile_pat
# Use a heredoc to unconditionally build the pat_ardop_listen.service file

function unitfile_pat() {

    # ==== pat_listen service
    service="pat_listen"
    pat_service_file="/etc/systemd/system/$service.service"

    sudo tee $pat_service_file > /dev/null << EOT
[Unit]
Description="pat ax25 listener"
After=network.target
Requires=rigctld
#Wants=rigctld

[Service]
User=$USER
Environment="HOME=/home/$USER/"
ExecStart=/usr/bin/pat --listen="ax25" "http"
WorkingDirectory=/home/$USER/
StandardOutput=inherit
StandardError=inherit
Restart=no

[Install]
WantedBy=multi-user.target
EOT

    $SYSTEMCTL daemon-reload
}

# ===== function is_ardop_service
function is_ardop_service() {

    retcode=1
    service_file="/etc/systemd/system/pat_listen.service"
    if [ -e "$service_file" ] ; then
        grep -iq "ardop" $service_file
	if [ $? -eq 0 ] ; then
	    retcode=0
	fi
    fi

    return "$retcode"
}

# ===== function is_direwolf_running

function is_direwolf_running() {

    retcode=1
    service="direwolf"
    if $SYSTEMCTL is-active --quiet "$service" ; then
	retcode=0
    else
        retcode=1
    fi

    return "$retcode"
}

# ===== function is_ardop_running
function is_ardop_running() {

    retcode=1
    process="ardop"
    pid_ardop="$(pidof $process)"
    ret=$?
    # Display process: name, pid, arguments
    if [ "$ret" -eq 0 ] ; then
        args=$(ps aux | grep "$pid_ardop " | grep -v "grep" | head -n 1 | tr -s '[[:space:]]' | sed -n "s/.*$process//p")
	grep -iq "ardop" <<< "$args"
	retcode="$?"
    fi
    dbgecho "${FUNCNAME[0]}: retcode=$retcode"
    return "$retcode"
}

# ===== function start_pat_service

# Use a heredoc to build the pat_listen.service file
# then Start pat ax25 listen service


function start_pat_service() {

    callsign=$(grep -i "\"mycall\":" $PAT_CONFIG_FILE | cut -f2 -d':' | sed -e 's/^[[:space:]]*//' | cut -f2 -d'"')
    if [ -z "$callsign" ] ; then
        echo "${FUNCNAME[0]} No call sign found, must run $(tput setaf 6)pat_install.sh --config $(tput sgr0)before starting pat service"
	exit 1
    else
        echo "${FUNCNAME[0]} Found call sign: $callsign"
    fi

    # ==== pat_listen service
    service="pat_listen"
    pat_service_file="/etc/systemd/system/$service.service"

    if [ -e "$pat_service_file" ] ; then
    	if is_ardop_service ; then
	    echo "$(tput setaf 1) === PAT listen is set to ARDOP will replace$(tput sgr0)"
	    echo
	    sudo rm $pat_service_file
	    unitfile_pat
	else
	    dbgecho
	    dbgecho "=== PAT listen is NOT set to ARDOP"
	    dbgecho
	fi
    else
        unitfile_pat
    fi

    status_port $service
    start_service $service
    status_port $service
}

# ===== function kill_ardop
function kill_ardop() {

    kill_flag="true"
    echo
    echo "DEBUG: kill_ardop: kill_flag $kill_flag"
    echo

    # ONLY_PAT_LISTEN
    # !!! NEED to check if running on a PI or an x86 platform
#    for process in "rigctld" "piardopc" "pat" "pat_listen" ; do
    for process in "rigctld" "$ARDOPC" "pat_listen" "pat" ; do

        pid_pat="$(pidof $process)"
        ret=$?
        # Display process: name, pid, arguments
        if [ "$ret" -eq 0 ] ; then
            args=$(ps aux | grep -i $pid_pat | grep -v "grep" | head -n 1 | tr -s '[[:space:]]' | sed -n "s/.*$process//p")
            echo "proc $process: $ret, pid: $pid_pat, args: $args"
        fi

        # Stop systemd services
        # !!! NEED to check if running on a PI or an x86 platform
        service="$process"
        if [ "$process" = "$ARDOPC" ] ; then
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

# ===== function stop_pat_service
# Requires argument of "true" to kill pat process

function stop_pat_service() {

    kill_flag=$1
    if [ -z "$kill_flag" ] ; then
        echo "${FUNCNAME[0]} needs an argument"
	exit
    fi

    for process in "pat_listen" "pat" ; do

        pid_pat="$(pidof $process)"
        ret=$?
        # Display process: name, pid, arguments
        if [ "$ret" -eq 0 ] ; then
            args=$(ps aux | grep -i $pid_pat | grep -v "grep" | head -n 1 | tr -s '[[:space:]]' | sed -n "s/.*$process//p")
            echo "proc $process: $ret, pid: $pid_pat, args: $args"
        else
            echo "${FUNCNAME[0]}: no process id found for $process"
        fi

        service="$process"
        if $SYSTEMCTL is-active --quiet "$service" ; then
            stop_service $service
        else
            # kill process
            if [ "$ret" -eq 0 ] && [ "$kill_flag" = "true" ] ; then
                echo "$process running with pid: $pid_pat, killing"
                kill $pid_pat
            fi
        fi
    done
}

# ===== function status_service

function status_service() {

    service="$1"
    service_status=0
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
	service_status=1
    fi
    return $service_status
}

# ===== function status_all_processes
# pat_listen has a process ID of pat

function status_all_processes() {

    # check for a PID of the PAT process
    process="pat"
    pid_pat="$(pidof $process)"
    ret=$?

    # Display process: name, pid, arguments
    if [ "$ret" -eq 0 ] ; then
        args=$(ps aux | grep "$pid_pat " | grep -v "grep" | head -n 1 | tr -s '[[:space:]]' | sed -n "s/.*$process//p")
        echo " proc $process: $ret, pid: $pid_pat, args: $args"
        grep -iq "ardop" <<< $args
	if [ $? -eq 0 ] ; then
            echo "$(tput setaf 1) === ardop process IS running, need to stop it$(tput sgr0)"
	fi
    else
        echo " proc $process: $ret, NOT running"
    fi
}

# ===== function audio_device_status

function audio_device_status() {

    audio_device="udrc"
    echo -n " == audio device $audio_device check: "
    if [ -e "/proc/asound/$audio_device/pcm0c/sub0/status" ] ; then
        grep -i "state:\|closed" "/proc/asound/$audio_device/pcm0c/sub0/status"
    else
        echo "device status file does NOT exist"
    fi
}

# ===== function get_pat_ax25_port

function get_pat_ax25_port() {

    port_used=$(grep -A 1 "ax25" $PAT_CONFIG_FILE | grep -i port | cut -f2 -d':' | cut -f1 -d',')
    # remove leading whitespace characters
    port_used="${port_used#"${port_used%%[![:space:]]*}"}"
    echo "debug2: $port_used"

    #Remove surronding quotes
    pat_port_used="${port_used%\"}"
    pat_port_used="${pat_port_used#\"}"
}

# ===== function confirm_ax25_port

function confirm_ax25_port() {
    port0=$(tail -n3 /etc/ax25/axports | grep -vE "^#|N0ONE" |  head -n 1 | cut -f1 -d' ')
    port1=$(tail -n3 /etc/ax25/axports | grep -vE "^#|N0ONE" |  tail -n 1 | cut -f1 -d' ')

    # Sets variable 'pat_port_used'
    get_pat_ax25_port

    echo "AX25 port names: $port0 & $port1, port used: $pat_port_used"
    if [ "$pat_port_used" != "$port0" ] && [ "$pat_port_used" != "$port1" ] ; then
        echo
	echo "  -> Need to edit $PAT_CONFIG_FILE ax25: port"
	echo
    fi
}

# ===== function pat_status

function pat_status() {
    if is_ardop_running ; then
        echo
        echo "$(tput setaf 1) === ARDOP is running$(tput sgr0)"
    fi
    if is_ardop_service ; then
        echo "$(tput setaf 1) === PAT listen is set to ARDOP$(tput sgr0)"
        echo
    fi

    service="draws-manager"
    status_service $service
    echo " Status for systemd service: $service: $IS_RUNNING and $IS_ENABLED"
    # if draws-manager is running, stop it.
    if [ $service_status = 0 ] ; then
        echo "Stopping service: $service"
	stop_service $service
    fi

    service="pat_listen"
    status_service $service
    echo " Status for systemd service: $service: $IS_RUNNING and $IS_ENABLED"

    if [ -z $ONLY_PAT_LISTEN ] ; then
        service="pat"
        status_service $service
        echo " Status for systemd service: $service: $IS_RUNNING and $IS_ENABLED"
    fi

    status_all_processes
    status_port $service
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

# ==== function get_mach_hardware
# Set variable $suffix to either amd64, armhf or arm64

function get_mach_hardware() {
    # For RPi 32 bit
    # pat_0.15.0_linux_armhf.deb (Raspberry Pi 32-bit)
    #
    # For 64 bit Intel
    # pat_0.15.0_linux_amd64.deb

    # uname -m
    #   x86_64
    #   armv7l
    #   aarch64

    mach_hardware="$(uname -m)"

    suffix=
    case $mach_hardware in

        "x86_64")
            suffix="amd64"
        ;;
        "armv7l")
            suffix="armhf"
        ;;
        "aarch64")
            suffix="arm64"
        ;;
        *)
            suffix="unknown"
        ;;
    esac

    echo "machine architecture: $mach_hardware, suffix: $suffix"
    if [ "$mach_hardware" = "unknown" ] ; then
        echo "Undefined machine hardware, exiting."
        exit 1
    fi
}

# ==== function display arguments used by this script

usage () {
	(
	echo "Usage: $scriptname [-d][-h][status][stop][start]"
        echo "                  No args will show status"
        echo "  -f | --force    Update systemd unit files"
	echo "  -d              Set DEBUG flag"
	echo
        echo "                  args with dashes must come before following arguments"
	echo
        echo "  start           start required PAT process"
        echo "  stop            stop all PAT process"
        echo "  status          display status of some processes"
        echo "  -h              Display this message."
        echo
	) 1>&2
	exit 1
}

# ===== main

USER=
ARDOPC="piardopc"

# Set variable $suffix for machine hardware
get_mach_hardware
if [ "$suffix" = "amd64" ] ; then
    ARDOPC="ardopc"
fi

# Check if running as root
if [[ $EUID != 0 ]] ; then
   SYSTEMCTL="sudo systemctl "
    USER=$(whoami)
    dbgecho "set sudo as user $USER"
else
   # Running as root
   get_user_name
   SYSTEMCTL="systemctl"
fi

while [[ $# -gt 0 ]] ; do
APP_ARG="$1"

case $APP_ARG in
    -d|--debug)
        DEBUG=1
        echo "Debug mode on"
   ;;
    -f|--force)
        FORCE_UPDATE=true
        echo "Force update mode on"
        echo "DEBUG: Updating systemd unitfiles"
        unitfile_pat
   ;;
    stop)
        echo "Kill PAT process"
        stop_pat_service "true"
	exit 0
    ;;
    start)

        if is_ardop_running ; then
            echo
	    echo "$(tput setaf 1) === ARDOP is running, will stop$(tput sgr0)"
	    kill_ardop
	    stop_service "ardop"
	fi
	if ! is_direwolf_running ; then
	    echo "$(tput setaf 1) === direwolf NOT running, will start$(tput sgr0)"
	    ax25-start
	fi

        dbgecho "Starting PAT"
	start_pat_service
        exit 0
    ;;
    status)
        pat_status
	audio_device_status
	confirm_ax25_port
        echo "Finished pat ax.25 status"
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

pat_status
audio_device_status
echo "Finished pat ax.25 status"
exit 0
