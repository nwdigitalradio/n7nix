#!/bin/bash
#
# Switch for 1200 baud and 9600 baud packet speed

USER=$(whoami)
#BIN_PATH="/home/$USER/n7nix/debug"
BIN_PATH="/home/$USER/bin"

SWITCH_FILE="/etc/ax25/packet_9600baud"
SPEED_CFG_FILE="/etc/ax25/baudrate.conf"
DIREWOLF_CFGFILE="/etc/direwolf.conf"

# ===== function speed_status
function speed_status() {
    if [ -e "$SWITCH_FILE" ] ; then
        echo "Switch file exists"
        # Anything in the file?
        if [ -s "$SPEED_CFG_FILE" ] ; then
            # Check for speed_chan
            echo "File: $SPEED_CFG_FILE NOT empty"
        else
            echo "Nothing in file: $SPEED_CFG_FILE"
        fi
    else
        echo "Switch file does NOT exist"
    fi
    echo "Display ax25dev-parms"
    echo
    echo "Display kissparms"
    for devname in `echo "ax0 ax1"` ; do
        PARMDIR="/proc/sys/net/ax25/$devname"
        if [ -d "$PARMDIR" ] ; then
            echo "Parameters for device $devname"

            echo -n "T1 Timeout: "
            cat $PARMDIR/t1_timeout

            echo -n "T2 Timeout: "
            cat $PARMDIR/t2_timeout
        else
            echo "Device: $devname does NOT exist"
        fi
    done

}

# ===== function usage

function usage() {
   echo "Usage: $scriptname [-s]" >&2
   echo "   -s      Display current status of speed."
   echo "   -h      Display this message"
   echo
}
# ===== main

while [[ $# -gt 0 ]] ; do
APP_ARG="$1"

case $APP_ARG in

   -s)
      echo "Display status"
      speed_status
      exit 0
   ;;
   -h|--help|?)
      usage
      exit 0
   ;;
   *)
      break;
   ;;

esac

shift # past argument
done



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
    echo "touch ret code: $?"

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
