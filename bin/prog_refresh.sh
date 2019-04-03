#!/bin/bash
#
# Refresh programs for a stale image.

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

# ===== main

# Do not run as root
if [[ $EUID -eq 0 ]]; then
    echo "*** DO NOT run as root ***" 2>&1
    exit 1
fi

# refresh n7nix repository

echo "Update scripts in n7nix directory"
cd
cd n7nix
git pull

# refresh local bin directory
echo "Refresh local bin directory"
cd config
./bin_refresh.sh

# refresh draws-manager repository
echo "Update draws manager"
cd /usr/local/var/draws-manager
sudo git pull

echo "Update HF programs"
# Update hf programs (this can take a long time)
# Display swap file size
echo "Swap file size check: $(swapon --show=SIZE --noheadings)"

# Change to directory containing script hf_verchk.sh as user (pi)
cd
cd n7nix/hfprogs

# Update source files & build
./hf_verchk.sh -u

# Check if swap file size was changed
swap_size=$(swapon --show=SIZE --noheadings)
if [ "$swap_size" != "100M" ] ; then
    echo "Change swap size back to default, currently set to $swap_size"
fi

echo "$(date "+%Y %m %d %T %Z"): $scriptname: Program Refresh script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
echo
