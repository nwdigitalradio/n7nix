#!/bin/bash

myname="`basename $0`"

# make sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "$myname: Must be root"
   exit 1
fi

# configure ax25
echo "Configure ax.25"
# Needs a callsign
source ../ax25/install.sh

# configure direwolf
# Needs a callsign
pushd ../direwolf
source ./install.sh
popd

# configure systemd
pushd ../systemd
source ./install.sh
popd

# install rmsgw
echo "Install RMS Gateway"
# needs a callsign
pushd ../rmsgw
source ./install.sh
popd

# configure rmsgw
echo "Configure RMS Gateway"

source ../rmsgw/config.sh

echo "app install script FINISHED"
echo
