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
VERSION="1.0"
DEVICE_TYPE="dinah"
DEVICE=
# List config files that will be edited
DIREWOLF_CFGFILE="/etc/direwolf.conf"
PORT_CFGFILE="/usr/local/etc/ax25/port.conf"
AX25D_CFGFILE="/usr/local/etc/ax25/ax25d.conf"
AXPORTS_CFGFILE="/usr/local/etc/ax25/axports"

modem_speed=1200

firmware_prodfile="/sys/firmware/devicetree/base/hat/product"
firmware_prod_idfile="/sys/firmware/devicetree/base/hat/product_id"
firmware_vendorfile="/sys/firmware/devicetree/base/hat/vendor"

NWDIG_VENDOR_NAME="NW Digital Radio"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function check_4
# Sets variable $DEVICE

function check_4_dinah() {

    #   echo "aplay command: "
    #   aplay -l
    aplay -l | grep -q -i "USB Audio Device"
    if [ "$?" -eq 0 ] ; then
        DEVICE="dinah"
    fi
}

# ===== function EEPROM id_check

# Return code:
# 0 = no EEPROM or no device tree found
# 1 = HAT found but not a UDRC
# 2 = UDRC
# 3 = UDRC II
# 4 = DRAWS
# 5 = 1WSpot

function id_check() {
# Initialize to EEPROM not found
udrc_prod_id=0

# Does firmware file exist
if [ -f $firmware_prodfile ] ; then
   # Read product file
   UDRC_PROD="$(tr -d '\0' < $firmware_prodfile)"
   # Read vendor file
   FIRM_VENDOR="$(tr -d '\0' < $firmware_vendorfile)"
   # Read product id file
   UDRC_ID="$(tr -d '\0' < $firmware_prod_idfile)"
   #get last character in product id file
   UDRC_ID=${UDRC_ID: -1}

   dbgecho "UDRC_PROD: $UDRC_PROD, ID: $UDRC_ID"

   if [[ "$FIRM_VENDOR" == "$NWDIG_VENDOR_NAME" ]] ; then
      case $UDRC_PROD in
         "Universal Digital Radio Controller")
            udrc_prod_id=2
         ;;
         "Universal Digital Radio Controller II")
            udrc_prod_id=3
         ;;
         "Digital Radio Amateur Work Station")
            udrc_prod_id=4
         ;;
         "1WSpot")
            udrc_prod_id=5
         ;;
         *)
            echo "Found something but not a UDRC: $UDRC_PROD"
            udrc_prod_id=1
         ;;
      esac
   else

      dbgecho "Probably not a NW Digital Radio product: $FIRM_VENDOR"
      udrc_prod_id=1
   fi

   if [ udrc_prod_id != 0 ] && [ udrc_prod_id != 1 ] ; then
      if (( UDRC_ID == udrc_prod_id )) ; then
         dbgecho "Product ID match: $udrc_prod_id"
	 DEVICE="udr"
      else
         echo "Product ID MISMATCH $UDRC_ID : $udrc_prod_id"
         udrc_prod_id=1
      fi
   fi
   dbgecho "Found HAT for ${PROD_ID_NAMES[$UDRC_ID]} with product ID: $UDRC_ID"
else
   # Get here if no UDRC or DRAWS firmware detected
   # RPi HAT ID EEPROM may not have been programmed in engineering samples
   # or there is no RPi HAT installed.
   udrc_prod_id=0
   # Detect a DINAH USB sound device
   DEVICE=
   check_4_dinah
fi

# Check for both udrc & dinah sound devices found
if [ "$DEVICE" = "udr" ] ; then
    old_device=$DEVICE
    check_4_dinah
    if [ "$old_device" != "$DEVICE" ] ; then
        echo "Change sound device from $old_device to $DEVICE"
    fi
fi

# Check for NO sound devices found
if [ -z "$DEVICE" ] ; then
    echo "No sound devices found"
fi

PORTNAME_1="${DEVICE}0"
PORTNAME_2="${DEVICE}1"

return $udrc_prod_id
}

# ===== function show_cfg
#
function show_cfg() {

    id_check
    id_check_ret=$?
    echo "id_check returned: $id_check_ret, port name: $PORTNAME_1"
    echo
    echo " === Check port.conf file"
    CFILE="/usr/local/etc/ax25/port.conf"
    grep -n -m1 "^speed=" $CFILE
    grep -n -m1 "^receive_out=" $CFILE

    # Get callsign
    echo
    echo " === Check ax25/axports file"
    CFILE="/usr/local/etc/ax25/axports"
    axports_line=$( tail -n3 $CFILE | grep -vE "^#|\[" |  head -n 1)
    callsign=$(echo $axports_line | tr -s '[[:space:]]' | cut -d' ' -f2 | cut -d '-' -f1)
    echo "Using call sign: $callsign"
    grep -i "$callsign" $CFILE

    echo
    echo " === Check ax25d.conf file"
    CFILE="/usr/local/etc/ax25/ax25d.conf"
    grep -i " via " $CFILE

#    echo
#    echo "Check ax25-upd file"
#    CFILE="/usr/local/etc/ax25/ax25-upd"

    echo
    echo " === Check direwolf.conf file"
    CFILE="/etc/direwolf.conf"
    parse_direwolf_config
}

# ===== function save_cfg_files
# Save all config files

function save_cfg_files() {

    testdir="/home/$USER/tmp/udrc"
    if [ -d "$testdir" ] ; then
        echo "save directory exists: $testdir"
    else
        echo "test directory ($testdir) does NOT exist, making"
	mkdir -p "$testdir"
    fi

    CFILE="port.conf"
    cp_dir="/usr/local/etc/ax25"
    echo
    echo "Coping file $CFILE"
    cp $cp_dir/$CFILE $testdir

    CFILE="ax25d.conf"
    echo
    echo "Coping file $CFILE"
    cp $cp_dir/$CFILE $testdir

    CFILE="axports"
    echo
    echo "Coping file $CFILE"
    cp $cp_dir/$CFILE $testdir

    CFILE="ax25-upd"
    echo
    echo "Coping file $CFILE"
    cp $cp_dir/$CFILE $testdir

    CFILE="direwolf.conf"
    cp_dir="/etc"
    echo
    echo "Coping file $CFILE"
    cp $cp_dir/$CFILE $testdir
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

# ===== function config_dw_1chan
# Configure direwolf to:
#  - use only one direwolf channel for CM108 sound card

function config_dw_1chan() {
    sudo sed -i -e "0,/^ADEVICE .*/ s/^ADEVICE .*/ADEVICE plughw:CARD=Device,DEV=0/"  $DIREWOLF_CFGFILE
    if [ "$?" -ne 0 ] ; then
        echo "sed failed with var: ADEVICE on file: $DIREWOLF_CFGFILE"
    fi
    sudo sed -i -e '/^ACHANNELS 2/ s/2/1/' $DIREWOLF_CFGFILE
    if [ "$?" -ne 0 ] ; then
        echo "sed failed with var: ACHANNELS on file: $DIREWOLF_CFGFILE"
    fi
    sudo sed -i -e "0,/^PTT GPIO.*/ s/PTT GPIO.*/PTT CM108/" $DIREWOLF_CFGFILE
    if [ "$?" -ne 0 ] ; then
        echo "sed failed with var: PTT GPIO on file: $DIREWOLF_CFGFILE"
    fi
}

# ===== function config_dw_2chan
# Edit direwolf.conf to use both channels (channel 0 & 1) of a DRAWS HAT

function config_dw_2chan() {

#   sudo sed -i -e "0,/^ADEVICE .*/ s/^ADEVICE .*/ADEVICE draws-capture-$CONNECTOR draws-playback-$CONNECTOR/"  $DIREWOLF_CFGFILE
    sudo sed -i -e "0,/^ADEVICE .*/ s/^ADEVICE .*/ADEVICE plughw:CARD=udrc,DEV=0 plughw:CARD=udrc,DEV=0/"  $DIREWOLF_CFGFILE
    if [ "$?" -ne 0 ] ; then
        echo "sed failed on file: $DIREWOLF_CFGFILE"
    fi
    sudo sed -i -e '/^ACHANNELS 1/ s/1/2/' $DIREWOLF_CFGFILE
    if [ "$?" -ne 0 ] ; then
        echo "sed failed on file: $DIREWOLF_CFGFILE"
    fi
    # Assume direwolf config was previously set up for 2 channels
    sudo sed -i -e "0,/^PTT GPIO.*/ s/PTT GPIO.*/PTT GPIO 12/" $DIREWOLF_CFGFILE
    if [ "$?" -ne 0 ] ; then
        echo "sed failed on file: $DIREWOLF_CFGFILE"
    fi
}
# ===== function config_port
# Edit /usr/local/etc/ax25/port.conf file for speed parameter

function config_port() {

    # Get device parmater
    device_param=$(grep -m1 "^Device=" $PORT_CFG_FILE | cut -f2 -d'=')

    # check device parameter, switch to dinah
    DEVICE="dinah"
    if [ "$device_param = "udr ] ; then
        # Edit device parameter
        # Modify first occurrence of device configuration line
        sudo sed -i -e "0,/^device=/ s/^device=.*/device=${DEVICE}/" $PORT_CFGFILE
        if [ "$?" -ne 0 ] ; then
            echo "sed failed with var: speed on file: $PORT_CFGFILE"
        fi
    fi

    # Get speed parameter
    speed_param=$(grep -m1 "^speed=" $PORT_CFGFILE | cut -f2 -d'=')

    # Check speed parameter
    if [ "$peed_param != "$modem_speed ] ; then
        # Edit speed parameter
        # Modify first occurrence of MODEM configuration line
        sudo sed -i -e "0,/^speed=/ s/^speed=.*/speed=${modem_speed}/" $PORT_CFGFILE
        if [ "$?" -ne 0 ] ; then
            echo "sed failed with var: speed on file: $PORT_CFGFILE"
        fi
    fi
}

# ===== function config_ax25d
#
# Change port name from udrc to dinah
function config_ax25d() {

    dbgecho "${FUNCNAME[0]}:"
    grep -i "udr" $AX25D_CFGFILE
    sudo sed -i -e "/udr/ s/udr/dinah/" $AX25D_CFGFILE
    if [ "$?" -ne 0 ] ; then
        echo "sed failed with var: udr on file: $AX25D_CFGFILE"
    fi
}

# ===== function config_axports
#
# Change port name from udrc to dinah
function config_axports() {

    dbgecho "${FUNCNAME[0]}:"
    grep -i "udr" $AXPORTS_CFGFILE
    sudo sed -i -e "/udr/ s/udr/dinah/" $AXPORTS_CFGFILE
    if [ "$?" -ne 0 ] ; then
        echo "sed failed with var: udr on file: $AXPORTS_CFGFILE"
    fi
}

# ===== function edit config files
#
function edit_cfg() {
    echo "Edit Configuration files for DEVICE: $DEVICE_TYPE"
    echo
    case $DEVICE_TYPE in
        dinah)
            echo "Configuring for a single USB sound card"
            config_dw_1chan
            config_port
	    config_ax25d
	    # only have a single port
	    # change udrc to dinah0
	    config_axports
        ;;
        udr)
            echo "Configuring for a 2 channel DRAWS sound card"
            config_dw_2chan
        ;;
        *)
            echo "Invalid device type: $DEVICE_TYPE"
        ;;
    esac
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
   echo "   -D <device type> | --device <device type>  Set device to either udr or dinah, default dinah"
   echo "   -e               Edit config files"
   echo "   -t               compare config files"
   echo "   -s               show status/config"
   echo "   -S <baud rate> | --speed <baud rate>  Set speed to 1200 or 9600 baud, default 1200"
   echo "   -d | --debug     set debug flag"
   echo "   -h               no arg, display this message"
   echo
}

# ===== main

echo "$scriptname Ver: $VERSION"

while [[ $# -gt 0 ]] ; do
key="$1"

case $key in
   -s|--status)
        show_cfg
        exit 1
    ;;

   -S|--speed)
      DEVICE_SPEED="$2"
      shift # past argument
      if [ "$DEVICE_SPEED" != "1200" ] && [ "$DEVICE_SPEED" != "9600" ] ; then
          echo "Invalid device speed: $DEVICE_SPEED, default to 1200 baud"
	  DEVICE_SPEED="1200"
      fi
      echo "DEBUG setting device speed to: $DEVICE_SPEED"
      set_speed
    ;;

   -D|--device)
      DEVICE_TYPE="$2"
      shift # past argument
      if [ "$DEVICE_TYPE" != "dinah" ] && [ "$DEVICE_TYPE" != "udr" ] ; then
          echo "Invalid device type: $DEVICE_TYPE, default to dinah device"
	  DEVICE_TYPE="dinah"
      fi
      echo "DEBUG device type & port number: $DEVICE_TYPE$PORT_NUM"
    ;;
   -e)
       save_cfg_files
       edit_cfg
       exit 0
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

