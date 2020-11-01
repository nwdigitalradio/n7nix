#!/bin/bash

USER=$(whoami)
QUIET=

# Check if there are any args on command line
# Use to quiet output
if (( $# != 0 )) ; then
   QUIET="-q"
fi

sudo /home/$USER/bin/ax25-stop $QUIET
sleep 1
sudo /home/$USER/bin/ax25-start $QUIET
