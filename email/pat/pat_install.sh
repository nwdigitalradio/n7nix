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

echo "FOR REFERENCE ONLY, DO NOT USE"

patver="0.9.0"

echo " == Get pat ver: $patver"
wget https://github.com/la5nta/pat/releases/download/v${patver}/pat_${patver}_linux_armhf.deb
if [ $?  -ne 0 ] ; then
    echo "Failed getting pat deb file"
else
    echo " == Installpat ver: $patver"
    sudo dpkg -i pat_${patver}_linux_armhf.deb
fi

# pat connect ardop:///LA1J?freq=3601.5
# pat connect ardop:///K7HTZ?freq=14108.5

exit 0
