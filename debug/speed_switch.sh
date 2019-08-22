#!/bin/bash
#
# Switch for 1200 baud and 9600 baud packet speed

USER=$(whoami)
#BIN_PATH="/home/$USER/n7nix/debug"
BIN_PATH="/home/$USER/bin"

SWITCH_FILE="/etc/ax25/packet_9600baud"
DIREWOLF_CFGFILE="/etc/direwolf.conf"


if [ -e "$SWITCH_FILE" ] ; then
    # For 1200 baud packet
    echo
    echo "Removing 9600 baud speed switch file"
    echo
    sudo rm $SWITCH_FILE
    echo "rm ret code: $?"
    if [ -e "$SWITCH_FILE" ] ; then
        echo "switch failed, $SWITCH_FILE still exists"
        exit 1
    fi

    echo
    echo "=== set direwolf 1200 baud speed"

    # uncomment 1200 baud line
    sudo sed -i '/^#MODEM 1200/ s/^#//' $DIREWOLF_CFGFILE

    # Comment out any 9600 lines
    sudo sed -i -e "/^MODEM 9600/ s/^/#/" $DIREWOLF_CFGFILE

else
    # For 9600 baud packet
    echo
    echo "Creating speed 9600 baud switch file"
    echo
    sudo touch $SWITCH_FILE
    echo "rm ret code: $?"

    echo
    echo "=== set direwolf 9600 baud speed"
    # uncomment 9600 baud line
    sudo sed -i '/^#MODEM 9600/ s/^#//' $DIREWOLF_CFGFILE

    # Comment out any 1200 lines
    sudo sed -i -e "/^MODEM 1200/ s/^/#/" $DIREWOLF_CFGFILE
fi

echo
echo "=== set alsa config"
sudo $BIN_PATH/setalsa-tmv71a.sh > /dev/null 2>&1

echo
echo "=== reset direwolf & ax25 parms"
$BIN_PATH/ax25-reset.sh
