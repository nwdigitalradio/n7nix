#!/bin/bash
#
# Edit config files to use CM108 sound dongle or a DRAWS hat
#
# Files modified:
#  /usr/local/etc/ax25
#    port.conf
#    ax25d.conf
#    axports
#    ax25-upd
#
# /etc/direwold.conf

scriptname="`basename $0`"

DEBUG=
DEVICE_TYPE="usb"
DIREWOLF_CFGFILE="/etc/direwolf.conf"
PORT_CFGFILE="/usr/local/etc/ax25/port.conf"
modem_speed=1200

# ===== function edit_cfg
#
function edit_cfg() {
    echo "Edit Configuration files for DEVICE: $DEVICE_TYPE"
    echo
    case $DEVICE_TYPE in
        usb)
            echo "Configuring for a single USB sound card"
            config_dw_1chan
            config_port
        ;;
        udrc)
            echo "Configuring for a 2 channel DRAWS sound card"
            config_dw_2chan
        ;;
        *)
            echo "Invalid device type: $DEVICE_TYPE"
        ;;
    esac
}

# ===== function show_cfg
#
function show_cfg() {

    echo
    echo "Check port.conf file"
    CFILE="/usr/local/etc/ax25/port.conf"
    grep -n -m1 "^speed=" $CFILE
    grep -n -m1 "^receive_out=" $CFILE

    # Get callsign
    echo
    echo "Check ax25/axports file"
    CFILE="/usr/local/etc/ax25/axports"
    axports_line=$( tail -n3 $CFILE | grep -vE "^#|\[" |  head -n 1)
    callsign=$(echo $axports_line | tr -s '[[:space:]]' | cut -d' ' -f2 | cut -d '-' -f1)
    echo "Using call sign: $callsign"

    echo
    echo "Check ax25d.conf file"
    CFILE="/usr/local/etc/ax25/ax25d.conf"
    grep -i " via " $CFILE

    echo
    echo "Check ax25-upd file"
    CFILE="/usr/local/etc/ax25/ax25-upd"

    echo
    echo "Check direwolf.conf file"
    CFILE="/etc/direwolf.conf"
    parse_direwolf_config
}

# ===== function compare_files
#
function compare_files() {
    testdir="/home/$USER/tmp/dinah"
    if [ -d "$testdir" ] ; then
        echo "test directory exists: $testdir"
    else
        echo "test directory ($testdir) does NOT exist"
	exit 1
    fi
    testdir="/home/$USER/tmp/udrc"
    if [ -d "$testdir" ] ; then
        echo "test directory exists: $testdir"
    else
        echo "test directory ($testdir) does NOT exist"
	exit 1
    fi
    echo "Comparing files in udr & dinah"
    testdir1="/home/$USER/tmp/dinah"
    CFILE="port.conf"
    echo
    echo "Comparing file $CFILE"
    diff $testdir/$CFILE $testdir1

    CFILE="ax25d.conf"
    echo
    echo "Comparing file $CFILE"
    diff $testdir/$CFILE $testdir1

    CFILE="axports"
    echo
    echo "Comparing file $CFILE"
    diff $testdir/$CFILE $testdir1

    CFILE="ax25-upd"
    echo
    echo "Comparing file $CFILE"
    diff $testdir/$CFILE $testdir1

    CFILE="direwolf.conf"
    echo
    echo "Comparing file $CFILE"
    diff $testdir/$CFILE $testdir1
}

# ===== function config_port
# Configure /usr/local/etc/ax25/port.conf file

function config_port() {
    # Modify first occurrence of MODEM configuration line
    sudo sed -i -e "0,/^speed=/ s/^speed=.*/speed= $modem_speed/" $PORT_CFGFILE
}

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
    numchan=$(grep "^ACHANNELS"  $DIREWOLF_CFGFILE | cut -d' ' -f2)
    if [ $numchan -eq 1 ] ; then
        echo "Setup for USB soundcard or split channels"
    else
        echo "Setup for DRAWS dual channel hat"
    fi
    audiodev=$(grep "^ADEVICE"  $DIREWOLF_CFGFILE | cut -d ' ' -f2)
    echo "Audio device: $audiodev"
    echo -n "PTT: "
    grep -i "^PTT " $DIREWOLF_CFGFILE

    grep -i "^MODEM" $DIREWOLF_CFGFILE
}

# ===== function usage
function usage() {
   echo "Usage: $scriptname [-D <device_name>][-h]" >&2
   echo "   -D Device type, either udrc or usb, default usb"
   echo "   -t compare files"
   echo "   -s show config"
   echo "   -d set debug flag"
   echo "   -h no arg, display this message"
   echo
}

# ===== main

while [[ $# -gt 0 ]] ; do
key="$1"

case $key in
   -e)
       edit_cfg
       exit 0
   ;;
   -s|--status)
        show_cfg
        exit 1
    ;;

   -D|--device)
      DEVICE_TYPE="$2"
      shift # past argument
      if [ "$DEVICE_TYPE" != "usb" ] && [ "$DEVICE_TYPE" != "udrc" ] ; then
          echo "Invalid device type: $DEVICE_TYPE, default to usb device"
	  DEVICE_TYPE="usb"
      fi
      echo "TEST device type & port number: $DEVICE_TYPE$PORT_NUM"
    ;;
   -t|--test)
       compare_files
       exit 0
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

show_cfg

exit 0

