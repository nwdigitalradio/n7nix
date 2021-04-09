#!/bin/bash
#
# pa-ctrl.sh
#
# stop and disable pulseaudio for both system & user services.

SYSTEMCTL="systemctl"

# Check if running as root
if [[ $EUID != 0 ]] ; then
    SYSTEMCTL="sudo systemctl"
    USER=$(whoami)
    dbgecho "set sudo as user $USER"
fi

echo " == stop system pulseaudio =="
$SYSTEMCTL --system stop pulseaudio
echo " == stop user pulseaudio =="
$SYSTEMCTL --user stop pulseaudio

# This only stops pulseaudio until the next reboot.
# To stop pulse audio between reboots you must also disable them.
echo
echo " == disable system pulseaudio =="
$SYSTEMCTL --system disable pulseaudio
echo " == disable user pulseaudio =="
$SYSTEMCTL --user disable pulseaudio

echo
echo " == user status =="
systemctl --no-pager --user status pulseaudio.service

echo
echo " == system status =="
systemctl --no-pager --system status pulseaudio.service
