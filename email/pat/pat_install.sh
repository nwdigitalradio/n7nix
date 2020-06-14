#!/bin/bash
#
# From https://github.com/la5nta/pat/releases
# pat_0.9.0_linux_armhf.deb (Raspberry Pi)
#
# Install FAQ
# https://github.com/la5nta/pat/wiki/Install-FAQ
# "IC-706MKIIG": {"address": "localhost:4532", "network": "tcp"}
# "K3/KX3": {"address": "localhost:4532", "network": "tcp"}
#
#   "rig": "ic-706MKII",
#   "rig": "K3/KX3",

echo "FOR REFERENCE ONLY, DO NOT USE"
exit 0

wget https://github.com/la5nta/pat/releases/download/v0.9.0/pat_0.9.0_linux_armhf.deb
dpkg -i pat_0.9.0_linux_armhf.deb

# pat connect ardop:///LA1J?freq=3601.5
# pat connect ardop:///K7HTZ?freq=14108.5
