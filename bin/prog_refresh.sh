#!/bin/bash
#
# Refresh programs for a stale image.

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

# ===== Display program help info
#
usage () {
	(
	echo "Usage: $scriptname [-u][-l][-h]"
        echo "    No arguments displays current & installed versions."
        echo "    -u Set application update flag."
        echo "    -l display local version only."
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
        -l)
            echo "Display local version only."
            /home/$USER/n7nix/hfprogs/hf_verchk.sh -l
            /home/$USER/n7nix/xastir/xs_verchk.sh -l
            /home/$USER/n7nix/gps/gp_verchk.sh -l
            exit
        ;;
        -u)
            echo "Update programs"
            echo
            UPDATE_FLAG=true
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

# refresh Debian package repository
echo
echo "Update from raspbian repo"

sudo apt-get update
if [[ $? > 0 ]] ; then
    echo
    echo "ERROR in apt-get update"
fi
sudo apt-get upgrade -q -y
if [[ $? > 0 ]] ; then
    echo
    echo "ERROR in apt-get upgrade"
fi

# refresh n7nix repository

echo
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

echo "Update Xastir"
cd
cd n7nix/xastir
./xs_verchk.sh -u

# Check if swap file size was changed
swap_size=$(swapon --show=SIZE --noheadings)
if [ "$swap_size" != "100M" ] ; then
    echo "Change swap size back to default, currently set to $swap_size"
fi

echo "$(date "+%Y %m %d %T %Z"): $scriptname: Program Refresh script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
echo
