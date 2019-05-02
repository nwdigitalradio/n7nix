#!/bin/bash
#
# Refresh programs for a stale image.

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
UPGRADE_ALL=true


# ===== Display program help info
#
usage () {
	(
	echo "Usage: $scriptname [-u][-l][-h]"
        echo "    No args will update all programs."
        echo "    -c displays current & installed versions."
        echo "    -l display local version only."
        echo "    -u update HAM programs only."
        echo "    -h display this message."
        echo
	) 1>&2
	exit 1
}

# ===== main

# Do not run as root
if [[ $EUID -eq 0 ]]; then
    echo "*** DO NOT run as root ***" 2>&1
    exit 1
fi

USER=$(whoami)

# Check for any command line arguments
# Command line args are passed with a dash & single letter
#  See usage function

while [[ $# -gt 0 ]] ; do

    key="$1"
    case $key in
        -c)
            # Compare current versions with installed versions
            /home/$USER/n7nix/hfprogs/hf_verchk.sh
            /home/$USER/n7nix/xastir/xs_verchk.sh
            /home/$USER/n7nix/gps/gp_verchk.sh
            exit
        ;;
        -l)
            # List local versions of programs built from source
            /home/$USER/n7nix/hfprogs/hf_verchk.sh -l
            /home/$USER/n7nix/xastir/xs_verchk.sh -l
            /home/$USER/n7nix/gps/gp_verchk.sh -l
            exit
        ;;
        -u)
            # Upgrade ham programs only
            UPGRADE_ALL=false
        ;;
        -h)
            usage
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

if $UPGRADE_ALL ; then
    # refresh Debian package repository
    echo
    echo "Update from raspbian repo"

    sudo apt-get -qq update
    if [[ $? > 0 ]] ; then
        echo
        echo "ERROR in apt-get update"
    fi
    sudo apt-get -q -y upgrade
    if [[ $? > 0 ]] ; then
        echo
        echo "ERROR in apt-get upgrade"
    fi
fi

# refresh n7nix repository

echo
echo "Update scripts in n7nix directory"
cd
cd n7nix
git pull

# Check raspbian repo update didn't install conflicting AudioSense-Pi
# drivers
bin/chk_conflict.sh

# refresh local bin directory
echo "Refresh local bin directory"
cd config
./bin_refresh.sh

# refresh split-channels repository
echo "Update split-channels"
cd
cd split-channels
sudo git pull

# refresh draws-manager repository
echo "Update draws manager"
cd /usr/local/var/draws-manager
sudo git pull
sudo cp -u /usr/local/var/draws-manager/draws-manager.service /etc/systemd/system/

echo "Update HF programs"
# Update hf programs (this can take a long time)
# Display swap file size
echo "Swap file size check: $(swapon --show=SIZE --noheadings)"

# Change to directory containing script hf_verchk.sh as user (pi)
cd
cd n7nix/hfprogs

# Update source files & build
./hf_verchk.sh -u

cd
cd n7nix/xastir
./xs_verchk.sh -u

cd
cd n7nix/gps
./gp_verchk.sh -u

# Check if swap file size was changed
swap_size=$(swapon --show=SIZE --noheadings)
if [ "$swap_size" != "100M" ] ; then
    echo "Change swap size back to default, currently set to $swap_size"
fi

# Only put a log entry if install script was called
echo "$(date "+%Y %m %d %T %Z"): $scriptname: Program Refresh script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
echo
