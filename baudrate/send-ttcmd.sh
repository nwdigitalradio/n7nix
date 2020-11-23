#!/bin/bash
#
# Output a wav file to a sound card
# Used to output DTMF tones to set baud rate on a remote system
#
# Usage:
#   send-ttcmd.sh [-c _connector_location_]
#
# Uses dtmf-generator python program to make wav file
# python3.7 dtmf-generator.py -p BA236288*A6B76B4C9B7# -f 20000 -t 0.08 -s 0.08 -o dtmfcmd.wav -a 90 -d
#

DEBUG=
DEBUG1=
USER=
DW_STOP=false

scriptname="`basename $0`"

# Force generation of wav file even if it already exists.
FORCE_GEN=
CALLSIGN="N0ONE"
CALLSIGN_ARG=false
AX25_CFGDIR="/usr/local/etc/ax25"
AXPORTS_FILE="$AX25_CFGDIR/axports"
PORT_CFG_FILE="/etc/ax25/port.conf"
DW_TT_LOG_FILE="/var/log/direwolf/dw-log.txt"

# For display to console
TEE_CMD="sudo tee -a $DW_TT_LOG_FILE"

# NWDR Draws ONLY
# default connector location, use left connector on a draws hat
udrc_prod_id=4
connector="left"

# Set default Touch Tone generation method to one wav file
tone_gen_method="file"

PROD_ID_NAMES=("INVALID" "INVALID" "UDRC" "UDRC II" "DRAWS" "1WSpot")
NWDIG_VENDOR_NAME="NW Digital Radio"

wavefile="dtmfcmd.wav"
#default to left channel on a DRAWS hat
# gpio_pin can be either 12 or 23
gpio_pin=12
# default baudrate
baudrate="1200"

CMDSTR="BA236288*A6B76B4C9B7#"
declare -A dmtffreq=( \
[1 1]=697 [1 2]=1209 [2 1]=697 [2 2]=1336 [3 1]=697 [3 2]=1477 [A 1]=697 [A 2]=1633 \
[4 1]=770 [4 2]=1209 [5 1]=770 [5 2]=1336 [6 1]=770 [6 2]=1477 [B 1]=770 [B 2]=1633 \
[7 1]=852 [7 2]=1209 [8 1]=852 [8 2]=1336 [9 1]=852 [9 2]=1477 [C 1]=852 [C 2]=1633 \
[* 1]=941 [* 2]=1209 [0 1]=941 [0 2]=1336 [# 1]=941 [# 2]=1477 [D 1]=941 [D 2]=1633 )

## Radio frequency definitions in Kilohertz
BAND_2M_LO_LIM=144000
BAND_2M_HI_LIM=148000
# 420 to 430 MHz is prohibited north of Line A
BAND_440_LO_LIM=430000
BAND_440_HI_LIM=450000

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

# ===== function debugecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function ctrl_c
# Shut off both PTT gpio's

function ctrl_c() {
        echo "** carrier off from trapped CTRL-C"
	gpio -g write 12 0
	gpio -g write 23 0
	exit
}

# ===== function error_exit

function error_exit() {
    errmsg=$1
    echo "ERROR: $errmsg"
    usage
    exit 1
}

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

function use_sox() {
    # Verify required programs are installed
    for prog_name in `echo ${PROGLIST}` ; do
         dbgecho "DEBUG: is program: $prog_name installed"
         type -P $prog_name &> /dev/null
         if [ $? -ne 0 ] ; then
             echo "$scriptname: Need to Install $prog_name program"
             NEEDPKG_FLAG=true
         fi
    done
    if [ "$NEEDPKG_FLAG" = "true" ] ; then
        echo "Installing required packages"
        dbgecho "Debian packages: for aplay install alsa-utils, for gpio, install wiringpi"
        sudo apt-get -y -q install alsa-utils sox
        if [ ! -e "/usr/local/src/wiringpi-latest.deb" ] ; then
            # Need wiringPi version 2.52 for Raspberry Pi 4 which is not yet in Debian repos.
            wget -P /usr/local/src https://project-downloads.drogon.net/wiringpi-latest.deb
        fi
        sudo dpkg -i /usr/local/src/wiringpi-latest.deb
    fi
}

# ===== function device_name_verify
# Verify that sound card device exists

function device_name_verify() {
    retcode=0
    return $retcode
}

# ===== function check_speed_config
# arg1 - requested baud rate
# Check modem baud rate amoung:
#   port.conf,
#   direwold config file
#   Touch Tone requested speed

function check_speed_config() {

    req_brate="$1"

    # Initialize baudrate boolean to false
    change_brate=0

    # from port config file: baud rate for left connector
    port_speed0=$(grep -i "^speed=" $PORT_CFG_FILE | head -n 1)
    # Get string after match string (equal sign)
    port_speed0="${port_speed0#*=}"

    # from direwolf config file: baud rate for channel 0
    # first occurrence of MODEM keyword
    dw_speed0=$(grep  "^MODEM" /etc/direwolf.conf | sed -n '1 s/.* //p')

    # Reference
    # baud rate for channel 1 in direwolf config file
    # second occurrence
    #dw_speed1=$(grep  "^MODEM" /etc/direwolf.conf | sed -n '2 s/.* //p')

    # Check baud rate against port.conf file
    if [ "$port_speed0" = "${req_brate}" ] ; then
        # last entry to log file
        dbgecho "port.conf: No config necessary: baudrate: ${req_brate}" | $TEE_CMD
    else
        # log file entry
        dbgecho "port.conf: Requested baudrate: ${req_brate}, current baudrate: $port_speed0" | $TEE_CMD
        change_brate=1
    fi

    # Check baud rate against direwolf config file
    if [ "$dw_speed0" = "${req_brate}" ] ; then
        # log file entry
        dbgecho "direwolf.conf: No config necessary: baudrate: ${req_brate}" | $TEE_CMD
        # Verify with port file
        if [ $change_brate -eq 1 ] ; then
            echo "ERROR: Mismatch in baud rates between port.conf ($port_speed0) & direwolf.conf ($dw_speed0)" | $TEE_CMD
        fi
    else
        # log file entry
        dbgecho "direwolf.conf: Requested baudrate: ${req_brate}, current baudrate: $dw_speed0" | $TEE_CMD
        # Verify with port file
        if [ $change_brate -eq 0 ] ; then
            echo "ERROR: Mismatch in baud rates between port.conf ($port_speed0) & direwolf.conf ($dw_speed0)" | $TEE_CMD
        fi

        change_brate=1
    fi
    return $change_brate
}

# ===== function gen_wave_file
# Generate a single Touch Tone wave file
# Plays a little faster than the individual playing of each touch tone

function gen_wave_file() {
    ## Generate individual Two Tone files
    for (( i=0; i < ${#CMDSTR}; i++)) ; do
        tonechar="${CMDSTR:$i:1}"

        # play -q -n synth 0.1 sin ${dmtffreq[$tonechar 1]} sin ${dmtffreq[$tonechar 2]} remix 1,2 2> /dev/null

        output_name="tmp_ttcmd_$i.wav"
        # sox -n $output_name synth 0.1 sin ${dmtffreq[$tonechar 1]} sin ${dmtffreq[$tonechar 2]} remix 1,2 silence 1 0.50 0.1%
        sox -n $output_name synth 0.1 sin ${dmtffreq[$tonechar 1]} sin ${dmtffreq[$tonechar 2]} remix 1,2
    done

    # generate 0.1 second of silence for space between each tone pair
    silence_file="silence.wav"
    if [ ! -e $silence_file ]  || [ ! -z $FORCE_GEN ] ; then
#        sox -n -r 44100 -c 2 $silence_file trim 0.0 0.5
         dbgecho "ttcmd silence wav file created"
         sox -n -r 48000 -c 2 $silence_file trim 0.0 0.5
    fi
    sox -n $silence_file trim 0.0 0.04

    ## Concatenate all the individual Two Tone files into one wav file
    # sox short.au long.au longer.au
    # sox ttcmd_0.wav silence.wav ttcmd_1.wav ttcmd_final.wav

    # Start with silence
#    ttcmd_output_file="ttcmd_${CALLSIGN}_${baudrate}00.wav"
    if [ ! -e $ttcmd_output_file ] || [ ! -z $FORCE_GEN ] ; then
        dbgecho "ttcmd wav file: $ttcmd_output_file does NOT exist, creating ..."

        cp silence.wav $ttcmd_output_file

        # Concatenate all required tones for the Touch Tone command
        for (( i=0; i < ${#CMDSTR}; i++)) ; do
            sox $ttcmd_output_file tmp_ttcmd_$i.wav silence.wav ttcmd_tmp.wav
            mv ttcmd_tmp.wav $ttcmd_output_file
        done
    else
        dbgecho "Required ttcmd wav file: $ttcmd_output_file exists"
    fi
}

# ===== function send_ttones_file
# Generate a single wave file & play one file only
function send_ttones_file() {

   echo " == generate one wav file"
   gen_wave_file
   rm tmp_ttcmd_*.wav

   echo " == play one wav file"
   if [ -z $DEBUG1 ] ; then
       play -q $ttcmd_output_file
   fi
}

# ===== function send_ttones_individ
# Send individually generated Touch Tone

function send_ttones_individ() {

    # This does not work
    #aplay -vv -D hw:CARD=udrc,DEV=0 $wavefile
    # *this works*
    ### aplay -vv -f s16_LE -D plughw:CARD=udrc,DEV=0 $wavefile

    #aplay -vv -D "plughw:1,0" $wavefile
    #aplay -vv -f s32_LE -c 2 -d 20 -D plughw:2,0 $wavefile

    # play touch tones individually

    echo " == play individual tones"

    # Perform a 'for' loop on each character in a string in Bash
    if [ ! -z $DEBUG  ] ; then
        for (( i=0; i < ${#CMDSTR}; i++)) ; do
            tonechar="${CMDSTR:$i:1}"
            if [ -z ${dmtffreq[$tonechar 1]} ] || [ -z ${dmtffreq[$tonechar 2]} ] ; then
                echo "Frequencies for DTMF char $tonechar is not defined"
            fi
            dbgecho "$tonechar First: ${dmtffreq[$tonechar 1]} Second: ${dmtffreq[$tonechar 2]}"
            if [ -z $DEBUG1 ] ; then
                play -q -n synth 0.1 sin ${dmtffreq[$tonechar 1]} sin ${dmtffreq[$tonechar 2]} remix 1,2 2> /dev/null
            fi
            # dbgecho "Return code from aplay: $?"
        done

    else
        for (( i=0; i < ${#CMDSTR}; i++)) ; do
            tonechar="${CMDSTR:$i:1}"
            play -q -n synth 0.1 sin ${dmtffreq[$tonechar 1]} sin ${dmtffreq[$tonechar 2]} remix 1,2  2> /dev/null
        done
    fi
}

tt_callsign_multipress() {
    call_ttones=$((grep -A 1 "multi-press method.*" <<< $(text2tt $CALLSIGN)) | tail -n1)
    dbgecho "tt1: $call_ttones"
    tt_str1=$(echo $call_ttones | cut -f2 -d'"')
    # parse the checksum
    tt_str2=$(echo $call_ttones | cut -f2 -d'=')
    # squish all the spaces
    checksum=$(echo $tt_str2 |tr -s '[[:space:]]')
    ttcallsign="A$tt_str1$checksum"
}

tt_callsign_twokey() {
    # Need to follow call sign with a symbol overlay and checksum
    overlay='4'
    call_ttones=$((grep -A 1 "two-key method.*" <<< $(text2tt $CALLSIGN$overlay)) | tail -n1)
    dbgecho "tt1: $call_ttones"
    tt_str1=$(echo $call_ttones | cut -f2 -d'"')
    # parse the checksum
    tt_str2=$(echo $call_ttones | cut -f2 -d'=')
    # squish all the spaces
    checksum=$(echo $tt_str2 |tr -s '[[:space:]]')
    ttcallsign="A$tt_str1$checksum"
}

tt_callsign_10digit() {

    call_ttones=$((grep -A 1 "10 digit callsign.*" <<< $(text2tt $CALLSIGN)) | tail -n1)
    dbgecho "tt1: $call_ttones"
    tt_str1=$(echo $call_ttones | cut -f2 -d'"')

    # Remove surrounding double quotes
    ttcallsign=${tt_str1%\"}
    ttcallsign=${ttcallsign#\"}
#    ttcallsign="A${ttcallsign}${checksum}"
}

# ===== function draws_id_check
# Verify the required sound card exists

function draws_id_check() {

    retcode=0 # error ret code
    # Verify that aplay enumerates udrc sound card

    CARDNO=$(aplay -l | grep -i udrc)

    if [ ! -z "$CARDNO" ] ; then
        dbgecho "udrc card number line: $CARDNO"
        CARDNO=$(echo $CARDNO | cut -d ' ' -f2 | cut -d':' -f1)
        echo "udrc is sound card #$CARDNO"
        retcode=2
    else
        echo "No udrc sound card found."
    fi
    return $retcode
}

# ===== function draws_setup

function draws_setup() {

    ## Verify a UDRC HAT is installed
    draws_id_check
    id_check_ret=$?
    if [ $id_check_ret -eq 0 ] || [ $id_check_ret -eq 1 ] ; then
        echo "ERROR: No UDRC or DRAWS found, id_check=$id_check_ret exiting ..."
        exit 1
    fi

    # Validate channel connector location
    # Set correct PTT gpio for channel 0 or 1
    # DRAWS Hat has channel 0 on left & channel 1 on right connector
    case $connector in
       left)
          # Check for UDRC II
          if [ $udrc_prod_id == 3 ]  ; then
             # uses audio channel 1 PTT gpio
             gpio_pin=23
          else
             # Original UDRC & DRAWS HAT use chan 0 PTT gpio
             gpio_pin=12
          fi
       ;;
       right)
          if [ $udrc_prod_id == 4 ] ; then
              # use channel 1 PTT gpio
              gpio_pin=23
          else
              # Original UDRC & UDRC II use chan 0 PTT gpio
              gpio_pin=12
          fi
       ;;
       *)
          error_exit "Wrong din connector location specified: $connector"
       ;;
    esac

    # Won't work unless gpio 4 is set to ALT 0
    # gpio 4 (BCM) is calld gpio. 7 by WiringPi
    mode_gpio7="$(gpio readall | grep -i "gpio. 7" | cut -d "|" -f 5 | tr -d '[:space:]')"
    if [ "$mode_gpio7" != "ALT0" ] ; then
        echo
        echo "  gpio 7 is in wrong mode: |$mode_gpio7|, should be: ALT0"
        echo "  Setting gpio set to mode ALT0"
        gpio mode 7 ALT0
        echo
    fi

    export AUDIODEV=plughw:CARD=udrc,DEV=0
    echo "Using audio device $AUDIODEV with play"
}

# ===== function draws_gpio_on

function draws_gpio_on() {
    echo "Using PTT GPIO $gpio_pin"

    # Enable PTT
    gpio -g mode $gpio_pin out
    gpio -g write $gpio_pin 1
}

# ===== function draws_gpio_off

function draws_gpio_off() {
    # Turn off PTT
    gpio -g write $gpio_pin 0
    dbgecho "Is carrier turned off gpio 12: $(gpio -g read 12), gpio 23: $(gpio -g read 23)?"
}

# ===== function usage
function usage() {
   echo "Usage: $scriptname [-c <connector>][-b <baudrate>][-h]" >&2
   echo "   -b <baudrate>           either 1200 or 9600 baud, default 1200"
   echo "   -c <connector_location> DRAWS left (mDin6) or right (hd15/mDin6), default: left"
   echo "   -C <call sign>          Specify a call sign"
   echo "   -f <frequency>          Frequency in kilohertz, exactly 6 digits."
   echo "   -t <tone_gen>           Tone generation method, either individ, file, default: file"
   echo "   -d                      set debug flag"
   echo "   -h                      no arg, display this message"
   echo
}

# ===== main

PROGLIST="gpio sox"
NEEDPKG_FLAG=false

# Check if running as root
if [[ $EUID != 0 ]] ; then
   USER=$(whoami)
   dbgecho "Running as user: $USER"
else
    echo
    echo "Not required to be root to run this script."
    exit 1
fi

LOCAL_BIN_PATH="/home/$USER/bin"
frequency=
ttfrequency=

dbgecho "Parse command line args"
# Command line args are passed with a dash & single letter
#  See usage function

while [[ $# -gt 0 ]] ; do
key="$1"

case $key in
   -b|--baudrate)
      baudrate="$2"
      shift # past argument
       if [ $baudrate -ne "1200" ] && [ $baudrate -ne "9600" ] ; then
           error_exit "Invalid baud rate selected, must be either '1200' or '9600'"
       fi
       dbgecho "Command Line: Setting baudrate to $baudrate"
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
   -c|--connector)
      connector="$2"
      shift # past argument
   ;;
   -f|--freq)
      frequency="$2"
      shift # past argument

       if ( (( frequency >= 144000 )) && (( frequency < 148000 )) ) ||
       ( (( frequency >= 430000 )) && (( frequency < 450000 )) ); then
           echo "Using frequency: $frequency"
       else
           error_exit "Invalid frequency selected ($frequency), must between $BAND_2M_LO_LIM & $BAND_2M_HI_LIM OR between $BAND_440_LO_LIM & $BAND_440_HI_LIM"       else
       fi
       dbgecho "Command Line: Setting frequency to $frequency"
   ;;
   -F|--force)
       FORCE_GEN=1
   ;;
   -d|--debug)
      DEBUG=1
      echo "Debug mode on"
   ;;
   -t|--tone)
       tone_gen_method="$2"
       shift # past argument

      if [ -z $tone_gen_method ] ; then
          error_exit "Invalid tone generation method ($tone_gen_method), must be either 'individ' or 'file'"
      elif [ $tone_gen_method != "individ" ] && [ $tone_gen_method != "file" ]  ; then
          error_exit "Invalid tone generation method ($tone_gen_method), must be either 'individ' or 'file'"
      else
          dbgecho "Tone method OK"
      fi
   ;;
   -h|--help|?)
      usage
      exit 0
   ;;
   *)
      # unknown option
      error_exit "Unknow option: $key"
   ;;
esac
shift # past argument or value
done


if [ $CALLSIGN_ARG = false ] ; then
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

# For reference, below is an example string with valid TTOBJ format
# - B<CN88> * A<N7NIX>
# CMDSTR="BA236288*A6B76B4C9B7#"
# CMDSTR="BA${$ttbaudrate}*A${ttcallsign}${checksum}#

## Convert callsign into TouchTone string
# Debug only
#text2tt $CALLSIGN

## Regardless of CALLSIGN string size last character gets dropped
## The last character of the callsign is being interpreted as the symbol
# overlay character.
#
# Add an extra trailing character ?

CALLSIGN="${CALLSIGN}"
echo "DEBUG: encoding call sign: $CALLSIGN"

tt_callsign_twokey
#tt_callsign_10digit
#tt_callsign_multipress

echo "DEBUG: Touch Tone object name: $ttcallsign"

## Convert requested baudrate into TouchTone string
# baudrate should only be 12 or 96 for 1200 baud & 9600 baud
if (( ${#baudrate} > 2 )) ; then
    baudrate=$(echo $baudrate | cut -c1-2)
fi
dbgecho "For Touch Tone request baud rate: $baudrate"

encoded_br="CN$baudrate"
tt_str1=$(text2tt $encoded_br | grep -A1 "Maidenhead Grid Square" | tail -n 1)

# Remove surrounding double quotes
ttbaudrate=${tt_str1%\"}
ttbaudrate=${ttbaudrate#\"}
ttbaudrate="BA${ttbaudrate}"

if [ ! -z $frequency ] ; then
    # Set baudrate & frequency
    ttfrequency="C${frequency}"
    CMDSTR="${ttbaudrate} * ${ttfrequency} * ${ttcallsign} #"

    echo "Touch Tone string check: $CMDSTR"
    echo "                 CMDSTR: BA236288*C144350*A6B76B4C9B7#"
    ttcmd_output_file="ttcmd_${CALLSIGN}_${baudrate}00_${frequency}.wav"
else
    # Only set baudrate
    CMDSTR="${ttbaudrate} * ${ttcallsign} #"
    echo "Touch Tone string check: $CMDSTR"
    echo "                 CMDSTR: BA236288  *A6B76B4C9B2B0#"
    ttcmd_output_file="ttcmd_${CALLSIGN}_${baudrate}00.wav"
fi

dbgecho "Verify required programs"
use_sox

# Need path to ax25-stop script
# - $USER variable should be set
# aplay will NOT work if direwolf or any other sound card program is running
pid=$(pidof direwolf)
if [ $? -eq 0 ] ; then
   echo "Direwolf is running, with a pid of $pid"
   echo " == Stopping Direwolf"
   sudo $LOCAL_BIN_PATH/ax25-stop -q
   DW_STOP=true
fi

echo "DEBUG: Sending command string: $CMDSTR"
echo "DEBUG: cmdstr: $CMDSTR, baud: ${ttbaudrate}, freq: ${ttfrequency}, call sign: $CALLSIGN, overlay: $overlay"

draws_setup
draws_gpio_on

## PTT is ON

if [ "$tone_gen_method" = "individ" ] ; then
    send_ttones_individ
elif [ "$tone_gen_method" = "file" ] ; then
    send_ttones_file
else
    draws_gpio_off
    error_exit "Do not recognize tone generating method $tone_gen_method"
fi

draws_gpio_off

## PTT is OFF

# Check if local baudrate config needs to change
check_speed_config ${baudrate}00
if [ $? -eq 1 ] ; then
    echo "Requested baudrate: ${baudrate}00 change" | $TEE_CMD
    $LOCAL_BIN_PATH/speed_switch.sh -b ${baudrate}00
else
   echo "Requested baudrate: $dw_speed0, NO change required"
fi

if [ "$DW_STOP" = "true" ] ; then
   echo " == Starting Direwolf"
   sudo $LOCAL_BIN_PATH/ax25-start -q
fi

exit 0
