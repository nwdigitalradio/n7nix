#!/bin/bash
#
# kern_release.sh
# - display current Raspberry Pi foundation released kernel version.
DEBUG=

release_url="https://downloads.raspberrypi.org/raspios_lite_armhf/release_notes.txt"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

if [[ $# -gt 0 ]] ; then
    DEBUG=1
fi

kern_ver_str=$(curl -s $release_url | grep -i "Linux kernel " | head -n 1)

dbgecho "debug: kernver: $kern_ver_str"
kern_ver=$(echo "$kern_ver_str" | awk '{print $NF}')

echo "kernver: $kern_ver"
