#!/bin/bash
#
# Edit direwolf config to use CM108 sound dongle or a DRAWS hat

scriptname="`basename $0`"
USER=
DEBUG=
DEVICE_TYPE="usb"
DIREWOLF_CFGFILE="/etc/direwolf.conf"


# ===== function config_dw_1chan
# Configure direwolf to:
#  - use only one direwolf channel for CM108 sound card

function config_dw_1chan() {
    sudo sed -i -e "0,/^ADEVICE .*/ s/^ADEVICE .*/ADEVICE plughw:CARD=Device,DEV=0/"  $DIREWOLF_CFGFILE
    sudo sed -i -e '/^ACHANNELS 2/ s/2/1/' $DIREWOLF_CFGFILE
    sudo sed -i -e "0,/^PTT GPIO.*/ s/PTT GPIO.*/PTT CM108/" $DIREWOLF_CFGFILE
}

# ===== function config_dw_2chan
# Edit direwolf.conf to use both channels (channel 0 & 1) of a DRAWS HAT

function config_dw_2chan() {

#   sudo sed -i -e "0,/^ADEVICE .*/ s/^ADEVICE .*/ADEVICE draws-capture-$CONNECTOR draws-playback-$CONNECTOR/"  $DIREWOLF_CFGFILE
    sudo sed -i -e "0,/^ADEVICE .*/ s/^ADEVICE .*/ADEVICE plughw:CARD=udrc,DEV=0 plughw:CARD=udrc,DEV=0/"  $DIREWOLF_CFGFILE
    sudo sed -i -e '/^ACHANNELS 1/ s/1/2/' $DIREWOLF_CFGFILE

    # Assume direwolf config was previously set up for 2 channels
    sudo sed -i -e "0,/^PTT GPIO.*/ s/PTT GPIO.*/PTT GPIO 12/" $DIREWOLF_CFGFILE
}

parse_direwolf_config() {
    numchan=$(grep "^ACHANNELS" /etc/direwolf.conf | cut -d' ' -f2)
    if [ $numchan -eq 1 ] ; then
        echo "Setup for USB soundcard or split channels"
    else
        echo "Setup for DRAWS dual channel hat"
    fi
    audiodev=$(grep "^ADEVICE" /etc/direwolf.conf | cut -d ' ' -f2)
    echo "Audio device: $audiodev"
    echo "PTT:"
    grep -i "^PTT " $DIREWOLF_CFGFILE
}

# ===== function usage
function usage() {
   echo "Usage: $scriptname [-D <device_name>][-h]" >&2
   echo "   -D Device type, either udrc or usb, default usb"
   echo "   -d set debug flag"
   echo "   -h no arg, display this message"
   echo
}

# ===== main

while [[ $# -gt 0 ]] ; do
key="$1"

case $key in

   -s|--status)
       parse_direwolf_config
       exit 1
   ;;

   -D|--device)
      DEVICE_TYPE="$2"
      shift # past argument
      if [ "$DEVICE_TYPE" != "usb" ] && [ "$DEVICE_TYPE" != "udrc" ] ; then
          echo "Invalid device type: $DEVICE_TYPE, default to usb device"
	  DEVICE_TYPE="usb"
      fi
   ;;
   -d|--debug)
      DEBUG=1
      echo "Debug mode on"
   ;;
   -h|--help|?)
      usage
      exit 0
   ;;
   *)
      # unknown option
      echo "Unknow option: $key"
      usage
      exit 1
   ;;
esac
shift # past argument or value
done

case $DEVICE_TYPE in
  usb)
      config_dw_1chan
  ;;
  udrc)
      config_dw_2chan
  ;;
  *)
      echo "Invalid device type: $DEVICE_TYPE"
  ;;

esac

exit 0
