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

# ===== main
# Check if NOT running as root
if [[ $EUID != 0 ]] ; then
   USER=$(whoami)
   dbgecho "Running as user: $USER"
   SYSTEMCTL="sudo systemctl"
fi

echo "=== edit /etc/watchdog.conf file"
# Add to end of file
sudo tee "$WD_CONFIG_FILE" > /dev/null << EOT
watchdog-device = /dev/watchdog
watchdog-timeout = 15
max-load-1 = 24
interval = 4    
EOT

echo "=== edit /boot/config.txt file"
# Add to end of file
sudo tee "$BOOT_CONFIG_FILE" > /dev/null << EOT
dtparam=watchdog=on
EOT

echo "=== enable watchdog systemd service"

$SYSTEMCTL enable watchdog
$SYSTEMCTL start watchdog
$SYSTEMCTL status watchdog
