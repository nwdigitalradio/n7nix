#!/bin/bash
#
#  dw_config.sh
#
# direwolf configuration script
# Original made to config direwolf for 1200/9600 baud devices
#
# Config direwolf:
# 1. Either single or dual channel DRAWS
#  1a. Single channel could be split channel
#      packet on left connector, HF mode on the right
# 2. Single channel CM108 sound device (DINAH)
# 3. Virtual channel with two Direwolf channels on single radio channel
#
# drw=DRAWS RPi hat, usb=USB sound card
#
# drw 1: draws 1 chan 1200 or 9600
# drw 2: draws 2 chan 1200 or 9600
# usb 1: dinah 1 chan 1200 or 9600
#
# drw v:
# usb v:
#       draws | usb 1 chan, 2 virtual devices


scriptname="`basename $0`"
USER=
DEBUG=
DEVICE_TYPE="usb"
CHAN_NUM="1"
CALLSIGN="N0ONE"

DIREWOLF_CFGFILE="/etc/direwolf.conf"
PULSEAUDIO_CFGFILE="/etc/asound.conf"
AXPORTS_FILE="/etc/ax25/axports"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function validate_callsign
# Validate callsign

function validate_callsign() {

    callsign="$1"
    sizecallstr=${#callsign}

    if (( sizecallstr > 6 )) || ((sizecallstr < 3 )) ; then
        echo "Invalid call sign: $callsign, length = $sizecallstr"
        return 1
    fi

    # Convert callsign to upper case
    CALLSIGN=$(echo "$callsign" | tr '[a-z]' '[A-Z]')
    return 0
}

# ===== function get_callsign

function get_callsign() {
    retcode=0
    # Check if call sign var has already been set
    if [ "$CALLSIGN" == "N0ONE" ] ; then
        echo "Enter call sign, followed by [enter]:"
        read -e callsign
    else
        echo "Error: call sign: $CALLSIGN"
    fi
    validate_callsign $callsign
    if [ $? -eq 0 ] ; then
        dbgecho "Using CALL SIGN: $CALLSIGN"
        retcode=1
    else
        echo "Bad callsign found: $callsign"
    fi
    return $retcode
}

function get_axports_callsign() {

    dbgecho "${FUNCNAME[0]} enter"

    retcode=1
    # get the first port line after the last comment
    #axports_line=$(tail -n3 $AXPORTS_FILE | grep -v "#" | grep -v "N0ONE" |  head -n 1)
    axports_line=$(tail -n3 $AXPORTS_FILE | grep -vE "^#|N0ONE" |  head -n 1)

    dbgecho "Using call sign from axports line: $axports_line"

    port=$(echo $axports_line | cut -d' ' -f1)
    # get rid of SSID
    callsign=$(echo $axports_line | tr -s '[[:space:]]' | cut -d' ' -f2 | cut -d '-' -f1)
    if [ ! -z $callsign ] ; then
        validate_callsign $callsign
        if [ $? -eq 0 ] ; then
            dbgecho "Using CALL SIGN: $CALLSIGN"
            retcode=0
        else
            echo "Bad callsign found: $callsign"
            CALLSIGN="N0ONE"
        fi
    fi
    return $retcode
}

# ===== function seq_backup
# Backup previous configuration file with a sequential name
# ie. never destroy a backup file
# arg 1 is path/root configuration file name

function seq_backup() {
    rootfname=$1
    today="$( date +"%Y%m%d" )"
    number=0
    # -- in printf statement: whatever follows should not be interpreted
    #    as a command line option to printf
    suffix="$( printf -- '-%02d' "$number" )"

    while test -e "$rootfname-$today$suffix.conf"; do
        (( ++number ))
        suffix="$( printf -- '-%02d' "$number" )"
    done

    fname="$rootfname-$today$suffix.conf"
    mv ${rootfname}.conf $fname
}

# function comment_second_chan
# comment out entire second channel configuration in direwolf config file

function comment_second_chan() {
    # Add comment character
    sed -i -e '/^CHANNEL 1/,/^$/ s/^\(^PTT GPIO.*\)/#\1/g' "$DIREWOLF_CFGFILE"
    sed -i -e '/^CHANNEL 1/,/^$/ s/^\(^MODEM.*\)/#\1/g'    "$DIREWOLF_CFGFILE"
    sed -i -e '/^CHANNEL 1/,/^$/ s/^\(^MYCALL.*\)/#\1/g'   "$DIREWOLF_CFGFILE"
    sed -i -e '/CHANNEL 1/,/^$/ s/^\(^CHANNEL.*\)/#\1/g'   "$DIREWOLF_CFGFILE"
}
# ===== function remove_dw_virt
# Remove 2 virtual channels

function remove_dw_virt() {
    # To delete 5 lines after a pattern (including the line with the pattern):
    # sed -e '/pattern/,+5d' file.txt

    # Delete the 7 lines following ADEVICE0
    sudo sed -i -e "0,/^ADEVICE0/,+7d" $DIREWOLF_CFGFILE
    # Delete the 7 lines following ADEVICE1
    sudo sed -i -e "0,/^ADEVICE1/,+7d" $DIREWOLF_CFGFILE
}

# ===== function config_dw_virt
# Configure direwolf to:
#  - use 2 virtual channels on a single channel using a DRAWS hat

function config_dw_virt() {

    ## comment out second channel
    comment_second_chan

    ## Replace ADEVICE with ADEVICE0 & ADEVICE1
    ## Setup ADEVICE0 as 1200 baud channel

    sudo sed -i -e "0,/^ADEVICE .*/a\
ADEVICE0 draws-capture-right draws-playback-right\
ACHANNELS 1\
ARATE 48000\
CHANNEL 0\
MYCALL ${CALLSIGN}-1\
MODEM 1200\
PTT GPIO 12" $DIREWOLF_CFGFILE
#    sudo sed -i -e "0,/^PTT GPIO.*/ s/PTT GPIO.*/PTT GPIO 12/" $DIREWOLF_CFGFILE
#    sudo sed -i -e '/^ACHANNELS 2/ s/2/1/' $DIREWOLF_CFGFILE


    ## Setup ADEVICE1 as 9600 baud channel

    sudo sed -i -e "0,/^PTT GPIO 12.*/a\

ADEVICE1 draws-capture-right-sub draws-playback-right-sub \
ACHANNELS 1\
ARATE 48000\
CHANNEL 0\
MYCALL ${CALLSIGN}-2\
MODEM 9600\
PTT GPIO 23" $DIREWOLF_CFGFILE

}

# ===== function config_pa
# Configure pulse audio
# if pulseaudio config file exists do not destroy it.

function config_pa() {

    if [ -f "$PULSEAUDIO_CFGFILE" ] ; then
        # get the path & filename without extension
        no_ext=${PULSEAUDIO_CFGFILE%.*}
	# This function determines an unused filename so that the
	# config file never gets over written.
        seq_backup "$no_ext"
        echo "Original pulseaudio config file saved as $fname"
    fi
    # This will bloto anything that is in the pulseaudio config file
    sudo tee $PULSEAUDIO_CFGFILE > /dev/null << EOT
pcm.draws-capture-left {
  type pulse
  device "draws-capture-left"
}
pcm.draws-playback-left {
  type pulse
  device "draws-playback-left"
}
pcm.draws-capture-right {
  type pulse
  device "draws-capture-right"
}
pcm.draws-playback-right {
  type pulse
  device "draws-playback-right"
}


pcm.draws-capture-left-sub {
  type pulse
  device "draws-capture-left"
}
pcm.draws-playback-left-sub {
  type pulse
  device "draws-playback-left"
}
pcm.draws-capture-right-sub {
  type pulse
  device "draws-capture-right"
}
pcm.draws-playback-right-sub {
  type pulse
  device "draws-playback-right"
}
EOT

}

# ===== function config_usb_1chan
# Configure direwolf to:
#  - use only one direwolf channel for CM108 sound card

function config_usb_1chan() {
    sudo sed -i -e "0,/^ADEVICE .*/ s/^ADEVICE .*/ADEVICE plughw:CARD=Device,DEV=0/"  $DIREWOLF_CFGFILE
    sudo sed -i -e '/^ACHANNELS 2/ s/2/1/' $DIREWOLF_CFGFILE
    sudo sed -i -e "0,/^PTT GPIO.*/ s/PTT GPIO.*/PTT CM108/" $DIREWOLF_CFGFILE
}

# ===== function config_drw_2chan
# Edit direwolf.conf to use both channels (channel 0 & 1) of a DRAWS HAT

function config_drw_2chan() {

    dbgecho "${FUNCNAME[0]} enter"
#   sudo sed -i -e "0,/^ADEVICE .*/ s/^ADEVICE .*/ADEVICE draws-capture-$CONNECTOR draws-playback-$CONNECTOR/"  $DIREWOLF_CFGFILE
    sudo sed -i -e "0,/^ADEVICE .*/ s/^ADEVICE .*/ADEVICE plughw:CARD=udrc,DEV=0 plughw:CARD=udrc,DEV=0/"  $DIREWOLF_CFGFILE
    sudo sed -i -e '/^ACHANNELS 1/ s/1/2/' $DIREWOLF_CFGFILE

    # Assume direwolf config was previously set up for 2 channels
    sudo sed -i -e "0,/^PTT GPIO.*/ s/PTT GPIO.*/PTT GPIO 12/" $DIREWOLF_CFGFILE
    dbgecho "${FUNCNAME[0]} exit"
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
    echo " == PTT"
    grep -i "^PTT " $DIREWOLF_CFGFILE
}

# ===== function usage
function usage() {
   echo "Usage: $scriptname [-C <callsign>][-c <channel_number>][-D <device_name>][-d][-s][-h]" >&2
   echo " Default to configuring a USB device on channel 0"
   echo "   -C <call sign>    Specify a HAM call sign"
   echo "   -c <chan number>  Channel number: 0, 1, b for both, v for virtual"
   echo "   -D <device>       Device type: drw or usb, default usb"
   echo "   -d                Set debug flag"
   echo "   -s                Display direwolf config status"
   echo "   -h                no arg, display this message"
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
   -C|--callsign)
      CALLSIGN_ARG=true
      CALLSIGN=$2
      shift # past argument
      validate_callsign $CALLSIGN
    if [ $? -eq 0 ] ; then
        dbgecho "Using CALL SIGN: $CALLSIGN"
        retcode=1
    else
        echo "Bad callsign found: $CALLSIGN"
        exit 1
    fi
   ;;
   -c|--chan)
     CHAN_NUM="$2"
     shift # past argument
     if [ "$CHAN_NUM" != "0" ] && [ "$CHAN_NUM" != "1" ] && [ "$CHAN_NUM" != "v" ] && [ "$CHAN_NUM" != "b" ] ; then
         echo "Invalid channel number: $CHAN_NUM, can be 0, 1, b or v, default to 0"
	 CHAN_NUM="0"
     else
         dbgecho "Channel number set to $CHAN_NUM"
     fi
   ;;
   -D|--device)
      DEVICE_TYPE="$2"
      shift # past argument
      if [ "$DEVICE_TYPE" != "usb" ] && [ "$DEVICE_TYPE" != "drw" ] ; then
          echo "Invalid device type: $DEVICE_TYPE, can be either 'usb' or 'drw', default to usb device"
	  DEVICE_TYPE="usb"
      else
          dbgecho "Device Type set to $DEVICE_TYPE"
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

keystring="# Configured with ${scriptname}"
search_str="# Command parameters are"

# determine if there is already an "$scriptname" entry
grep -i $scriptname $DIREWOLF_CFGFILE
retcode=$?

if [ $retcode -ne 0 ] ; then
    echo "DEBUG: First sed"
# Insert string after first blank line after $search_str
sudo sed -i "/${search_str}/,/^$/s/^$/#\n\
${keystring}, Channel: $CHAN_NUM, Device: ${DEVICE_TYPE}\
\n/" $DIREWOLF_CFGFILE
else
    echo "DEBUG: Second sed"
    sudo sed -i -e "0,/${keystring}.*/ s/# Configured with .*/${keystring}, Channel: $CHAN_NUM, Device: ${DEVICE_TYPE}/" $DIREWOLF_CFGFILE
fi
echo "DEBUG: Early exit"
diff direwolf.conf /etc
exit 0

dbgecho "Get a callsign: $CALLSIGN"
# Try to parse callsign from /etc/ax25/axports file
if [ $CALLSIGN = "N0ONE" ] ; then
    ## Get a valid callsign from axports file
    get_axports_callsign
    retcode="$?"

    dbgecho "retcode: $retcode from get_axports_callsign"

    if [ $retcode -ne 0 ] ; then

        ## Get a callsign from command line
        echo "prompt for a callsign:"
        while get_callsign ; do
            retcode=$?
            echo "Input error ($retcode), try again"
        done
    fi
fi

dbgecho "CALLSIGN set to: $CALLSIGN"

if [ $CHAN_NUM = "v" ] ; then
    config_dw_virt
else
    case $DEVICE_TYPE in
        usb)
            config_usb_1chan
        ;;
        drw)
            dbgecho "calling config_drw_2chan"
            config_drw_2chan
        ;;
        *)
            echo "Invalid device type: $DEVICE_TYPE"
       ;;

    esac

fi
exit 0
