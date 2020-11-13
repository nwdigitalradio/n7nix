#!/bin/bash

USER=$(whoami)
QUIET=

# Be sure NOT running as root
if [[ $EUID != 0 ]] ; then
    # NOT running as root
    USER=$(whoami)
else
    # Running as root,
    echo "Do NOT run as root."
    exit 1
fi

# Check if there are any args on command line
# Use to quiet output
if (( $# != 0 )) ; then
   QUIET="-q"
fi

sudo /home/$USER/bin/ax25-stop $QUIET
sleep 1
sudo /home/$USER/bin/ax25-start $QUIET
