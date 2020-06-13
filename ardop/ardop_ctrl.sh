#!/bin/bash
#
BIN="/usr/bin"
LBIN="/usr/local/bin"
LOCAL_BIN="/home/pi/bin"

SYSTEMD_DIR="/etc/systemd/system"
FORCE_UPDATE=

# for IC-706mkIIg
rignum=311
ic706_baud=4800

# ic-7300
sample_rate=48000

# draws
sample_rate=12000

function asoundfile() {
sudo tee $HOME/.asoundrc > /dev/null << EOT
pcm.ARDOP {
        type rate
        slave {
        pcm "hw:1,0"
        rate 48000
        }
}
EOT
}
function unitfile_rigctld() {
sudo tee /etc/systemd/system/rigctld.service > /dev/null << EOT
[Unit]
Description=rigctld
#Before=pat


[Service]
ExecStart=/usr/local/bin/rigctld -m $rignum -r /dev/ttyUSB0 -s $ic706_baud
WorkingDirectory=/home/pi/
StandardOutput=inherit
StandardError=inherit
Restart=no
User=pi


[Install]
WantedBy=multi-user.target
WantedBy=pat
EOT
}

function unitfile_ardop() {
sudo tee /etc/systemd/system/ardop.service > /dev/null << EOT
[Unit]
Description=ardopc - ARDOP softmodem for pi
After=network.target sound.target

[Service]
User=pi
ExecStart=/bin/sh -c "/home/pi/bin/piardopc 8515 pcm.ARDOP pcm.ARDOP -p GPIO=12"
#ExecStart=/bin/sh -c "/home/pi/bin/piardopc 8515 plughw:1,0 plughw:1,0 -p GPIO=12"
#ExecStart=/bin/sh -c "cd /tmp && /usr/local/bin/piardopc"
Restart=no

[Install]
WantedBy=multi-user.target
EOT
}

function unitfile_pat() {
sudo tee /etc/systemd/system/pat.service > /dev/null << EOT
[Unit]
Description=pat
#After=winlinkrms
#Before=network.target
Requires=rigctld
#Wants=rigctld

[Service]
User=pi
ExecStart=/usr/bin/pat http
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
    for process in "rigctld" "piardopc" "pat" ; do

        pid_pat="$(pidof $process)"
        ret=$?
        # Display process: name, pid, arguments
        if [ "$ret" -eq 0 ] ; then
            args=$(ps aux | grep -i $pid_pat | grep -v "grep" | head -n 1 | tr -s '[[:space:]]' | sed -n "s/.*$process//p")
            echo "proc $process: $ret, pid: $pid_pat, args: $args"
        else
            echo "proc $process: $ret, NOT running"
        fi
    done
}

# ===== function status_all_services

function status_all_services() {
    for service in "rigctld" "ardop" "pat" ; do
        status_service
    done
}

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
    fi
    $SYSTEMCTL --no-pager start "$service"
    if [ "$?" -ne 0 ] ; then
        echo "Problem starting $service"
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
        stop_service $service
    else
        echo "Service: $service is already stopped"
    fi
}

# ===== function kill_ardop
function kill_ardop() {
    kill_flag=$1


    for process in "rigctld" "piardopc" "pat" ; do

        pid_pat="$(pidof $process)"
        ret=$?
        # Display process: name, pid, arguments
        if [ "$ret" -eq 0 ] ; then
            args=$(ps aux | grep -i $pid_pat | grep -v "grep" | head -n 1 | tr -s '[[:space:]]' | sed -n "s/.*$process//p")
            echo "proc $process: $ret, pid: $pid_pat, args: $args"
        fi

        # Stop systemd service
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

# ===== function process_check

function process_check() {
    kill_flag=
    auddev="udrc"
    if [ ! -z $1 ] ; then
        kill_flag=true
        echo "kill flag set"
    fi
    echo
    echo "  === audio device $auddev check"
    if [ -e "/proc/asound/$auddev/pcm0c/sub0/status" ] ; then
        grep -i "state:" "/proc/asound/$auddev/pcm0c/sub0/status"
    else
        echo "Audio device status file does NOT exist"
    fi
    filename="$HOME/.asoundrc"
    if [ ! -e "$filename" ] || [ $FORCE_UPDATE = true ] ; then
        echo "File: $filename does not exist, creating"
        # create asound file
        asoundfile
    fi

    echo
    echo "  === process check"
    kill_ardop $kill_flag
}

# ===== function unitfile_update
# systemd unit file copy

function unitfile_update() {

    echo " == unit file update"
    for unit_file in "rigctld" "ardop" "pat" ; do
        case $unit_file in
            rigctld)
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
}

# ===== function systemd unit file check
# systemd unit file exists check

function unitfile_check() {

    retcode=0
    for file in "rigctld" "ardop" "pat" ; do
        if [ ! -e "$SYSTEMD_DIR/${file}.service" ] ; then
            retcode=1
            echo "Systemd unit file: $SYSTEMD_DIR/${file}.service NOT found."
        else
            systemctl status $file >/dev/null 2>&1
            status=$?
            echo "Service: $file, status: $status"
        fi
    done
    if [ "$retcode" -eq 0 ] && [ -z "$FORCE_UPDATE" ] ; then
        echo "All systemd service files found"
    else
        echo "Creating systemd service files."
        unitfile_update
        retcode=1
    fi
    return $retcode
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

while [[ $# -gt 0 ]] ; do
APP_ARG="$1"

case $APP_ARG in

    stop)
        echo "Kill all ardopc, rigctld & pat processes"
        # temporary until everything is started with systemd
        kill_ardop true
    ;;
    start)
        for service in "rigctld" "ardop" "pat" ; do
            start_service $service
        done
    ;;
    status)
        echo " == Ardop systemctl unit file check"
        unitfile_check
        retcode=$?
#        echo "DEBUG: retcode from unitfile_check: $retcode"
        if [ "$retcode" -eq 1 ] ; then
            echo " systemctl daemon-reload"
            $SYSTEMCTL daemon-reload
        fi

        echo " == Ardop process check"
        status_all_services
        status_all_processes
        exit 0
    ;;
    -f|--force)
        FORCE_UPDATE=true
        echo "Force update mode on"
   ;;
    -d|--debug)
        DEBUG=1
        echo "Debug mode on"
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

if [[ $# -eq 0 ]] ; then
    APP_ARG="status"
fi
unitfile_check
retcode=$?

#echo "DEBUG: retcode from unitfile_check: $retcode"

if [ "$retcode" -eq 1 ] ; then
    echo " systemctl daemon-reload"
    $SYSTEMCTL daemon-reload
fi

echo " == Ardop process check"
status_all_processes

echo "Finished ardop $APP_ARG"