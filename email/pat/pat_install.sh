#!/bin/bash
#
# From https://github.com/la5nta/pat/releases
# pat_0.9.0_linux_armhf.deb (Raspberry Pi)
#
# Install FAQ
# https://github.com/la5nta/pat/wiki/Install-FAQ
# Need to edit file: $HOME/.wl2k/config.json
#  mycall
#  secure_login_password
#  locator (Grid square locator ie. CN88nl)
#  hamlib_rigs:
#     "IC-706MKIIG": {"address": "localhost:4532", "network": "tcp"}
#     "K3/KX3": {"address": "localhost:4532", "network": "tcp"}
#  ardop: rig:
#   "rig": "ic-706MKII",
#   "rig": "K3/KX3",

#patver="0.11.0"
# Get current version number in repo
patver="$(curl -s https://raw.githubusercontent.com/la5nta/pat/master/VERSION.go | grep -i "Version = " | cut -f2 -d '"')"

# ===== function desktop_pat_file
# NOTE: This function is also in ardop/ardop_ctrl.sh
# Use a heredoc to build the Desktop/pat file

function desktop_pat_file() {
    # If running as root do NOT create any user related files
    if [[ $EUID != 0 ]] ; then
        # Set up desktop icon for PAT
        filename="$HOME/Desktop/pat.desktop"
        if [ ! -e $filename ] ; then

            tee $filename > /dev/null << EOT
[Desktop Entry]
Name=PAT - Mailbox
Type=Link
URL=http://localhost:8080
Icon=/usr/share/icons/PiX/32x32/apps/mail.png
EOT
        fi
    else
        echo
        echo " Running as root so PAT desktop file not created"
    fi
}

# ===== main

echo " == Get pat ver: $patver"
wget https://github.com/la5nta/pat/releases/download/v${patver}/pat_${patver}_linux_armhf.deb
if [ $?  -ne 0 ] ; then
    echo "Failed getting pat deb file"
else
    echo " == Installpat ver: $patver"
    sudo dpkg -i pat_${patver}_linux_armhf.deb
fi

desktop_pat_file

# pat connect ardop:///LA1J?freq=3601.5
# pat connect ardop:///K7HTZ?freq=14108.5

exit 0
