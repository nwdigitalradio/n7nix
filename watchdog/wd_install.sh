#!/bin/bash
#
# Install BCM2708 hardware watchdog
#

scriptname="`basename $0`"
WD_CONFIG_FILE="/etc/watchdog.conf"
BOOT_CONFIG_FILE="/boot/config.txt"
SYSTEMCTL="systemctl"

# ===== function dbgecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ==== function is_pkg_installed
function is_pkg_installed() {
   return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed")
}

# ===== function start_service

function start_service() {
    service="$1"
    echo "Checking service: $service"

    systemctl is-enabled --quiet "$service"
    if [ $? -ne 0 ] ; then
        echo "ENABLING $service"
        $SYSTEMCTL enable "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem ENABLING $service"
            exit
        fi
    fi

    if systemctl is-active --quiet "$service" ; then
        echo "Service: $service is already running"
    else

        $SYSTEMCTL --no-pager start "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem starting $service"
            systemctl status $service
            exit
        fi
    fi
}

# ===== main

# Check if NOT running as root
if [[ $EUID != 0 ]] ; then
   USER=$(whoami)
   dbgecho "Running as user: $USER"
   SYSTEMCTL="sudo systemctl"
fi

pkg_name="watchdog"
echo "=== check for $pkg_name package"

is_pkg_installed $pkg_name
if [ $? -eq 0 ] ; then
    echo "$scriptname: Will Install $pkg_name program"
    sudo apt-get install -y -q $pkg_name
else
    echo "$scriptname: $pkg_name alread installed"
fi

echo "=== edit $WD_CONFIG_FILE file"
if [ -e "$WD_CONFIG_FILE" ] ; then
    # Check if already configured
    grep -q "^watchdog-device" $WD_CONFIG_FILE
    if [ "$?" -ne 0 ] ; then
        # Add to end of file
        sudo tee -a "$WD_CONFIG_FILE" > /dev/null << EOT
watchdog-device = /dev/watchdog
watchdog-timeout = 15
max-load-1 = 24
interval = 4    
EOT
    else
        echo "watchdog already configured in $WD_CONFIG_FILE"
    fi
else
    echo "File: $WD_CONFIG_FILE does NOT exist"
fi

echo "=== edit $BOOT_CONFIG_FILE file"
# Check if already configured
grep -q "^dtparam=watchdog" $BOOT_CONFIG_FILE
if [ "$?" -ne 0 ] ; then

    # Add to end of file
    sudo tee -a "$BOOT_CONFIG_FILE" > /dev/null << EOT
dtparam=watchdog=on
EOT
else
    echo "watchdog already configured in $BOOT_CONFIG_FILE"
fi

echo "=== enable watchdog systemd service"

service="watchdog"
start_service $service
echo
echo "Service: $service status"
systemctl --no-pager status $service
