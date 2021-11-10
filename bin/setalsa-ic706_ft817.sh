#!/bin/bash
#
# setalsa-ic706_ft817.sh
# Audio channels, for HF on both channels
#
# For iCom IC-706mkIIG on left connector for HF and
#  Yaesu FT-817 on right connector also for HF
#
# For UDRC II, enable setting receive path from discriminator (DISC)
# This script ignores /etc/ax25/port.conf file
DEBUG=

RADIO="IC-706 & FT-817"
scriptname="`basename $0`"

asoundstate_file="/var/lib/alsa/asound.state"
ALSA_LOG_DIR="$HOME/tmp"
ALSA_LOG_FILE="$ALSA_LOG_DIR/alsa_mixer.log"

# Default to: ICOM  settings for left channel
#             YAESU settings for right channel
PCM_LEFT="-26.5"
PCM_RIGHT="-16.5"
LO_DRIVER_LEFT="-6.0"
LO_DRIVER_RIGHT="-6.0"
ADC_LEVEL_LEFT="8.0"
ADC_LEVEL_RIGHT="-2.0"

IN1_L='Off'
IN1_R='Off'
IN2_L="10 kOhm"
IN2_R="10 kOhm"

PTM_PL="P3"
PTM_PR="P3"

RECVSIG_LEFT="audio"
RECVSIG_RIGHT="audio"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function get product id of HAT
# Sets variable PROD_ID

function get_prod_id() {
    # Initialize product ID variable
    PROD_ID=
    prgram="udrcver.sh"
    which $prgram > /dev/null
    if [ "$?" -eq 0 ] ; then
        dbgecho "Found $prgram in path"
        $prgram -
        PROD_ID=$?
    else
        currentdir=$(pwd)
        # Get path one level down
        pathdn1=$( echo ${currentdir%/*})
        dbgecho "Test pwd: $currentdir, path: $pathdn1"
        if [ -e "$pathdn1/bin/$prgram" ] ; then
            dbgecho "Found $prgram here: $pathdn1/bin"
            $pathdn1/bin/$prgram -
            PROD_ID=$?
        else
            echo "Could not locate $prgram default product ID to DRAWS"
            PROD_ID=4
        fi
    fi
}


# ===== main

# SET DEBUG flag if there any command line args
if (( $# != 0 )) ; then
    DEBUG=1
fi

if [ ! -d $ALSA_LOG_DIR ] ; then
   mkdir -p $ALSA_LOG_DIR
fi

stateowner=$(stat -c %U $asoundstate_file)
if [ $? -ne 0 ] ; then
   "$scriptname: Command 'alsactl store' will not work, file: $asoundstate_file does not exist"
   exit
fi

# Check if HAT is a UDRC or UDRC II
#  - If found then use discriminator routing
get_prod_id
if [[ "$PROD_ID" -eq 2 ]] || [[ "$PROD_ID" -eq 3 ]] ; then
    echo "Detected UDRC or UDRC II, product ID: $PROD_ID"
    IN1_L='10 kOhm'
    IN1_R='10 kOhm'
    IN2_L="Off"
    IN2_R="Off"
    RECVSIG_LEFT="disc"
    RECVSIG_RIGHT="disc"
else
    dbgecho "UDRC or UDRC II not detected"
fi

# IN1 Discriminator output (FM function only, not all radios, 9600 baud packet)
# IN2 Compensated receive audio (all radios, 1200 baud and slower packet)

if [ ! -z "$DEBUG" ] ; then
    # Test new method
    echo "== DEBUG: $scriptname: Port Speed: $PORTSPEED_LEFT, $PORTSPEED_RIGHT  =="
    echo "RECVSIG: $RECVSIG_LEFT, $RECVSIG_RIGHT"
    echo "PCM: $PCM_LEFT, $PCM_RIGHT"
    echo "LO Driver Gain: ${LO_DRIVER_LEFT}dB,${LO_DRIVER_RIGHT}dB"
    echo "ADC Level: ${ADC_LEVEL_LEFT}dB,${ADC_LEVEL_RIGHT}dB"
    echo "Power Tune: ${PTM_PL}, ${PTM_PR}"
    echo "IN1: $IN1_L, $IN1_R"
    echo "IN2: $IN2_L, $IN2_R"
    echo
fi

echo >> $ALSA_LOG_FILE
date >> $ALSA_LOG_FILE
echo "Radio: $RADIO set from $scriptname" | tee -a $ALSA_LOG_FILE

amixer -c udrc -s << EOF >> $ALSA_LOG_FILE
sset 'PCM' "${PCM_LEFT}dB,${PCM_RIGHT}dB"
sset 'LO Driver Gain' "${LO_DRIVER_LEFT}dB,${LO_DRIVER_RIGHT}dB"
sset 'ADC Level' ${ADC_LEVEL_LEFT}dB,${ADC_LEVEL_RIGHT}dB

sset 'IN1_L to Left Mixer Positive Resistor' "$IN1_L"
sset 'IN1_R to Right Mixer Positive Resistor' "$IN1_R"
sset 'IN2_L to Left Mixer Positive Resistor' "$IN2_L"
sset 'IN2_R to Right Mixer Positive Resistor' "$IN2_R"

sset 'DAC Left Playback PowerTune'  $PTM_PL
sset 'DAC Right Playback PowerTune' $PTM_PR

#  Set default input and output levels
# Everything after this line is common to both audio channels

sset 'CM_L to Left Mixer Negative Resistor' '10 kOhm'
sset 'CM_R to Right Mixer Negative Resistor' '10 kOhm'

#  Turn off unnecessary pins
sset 'IN1_L to Right Mixer Negative Resistor' 'Off'
sset 'IN1_R to Left Mixer Positive Resistor' 'Off'

sset 'IN2_L to Right Mixer Positive Resistor' 'Off'
sset 'IN2_R to Left Mixer Negative Resistor' 'Off'

sset 'IN3_L to Left Mixer Positive Resistor' 'Off'
sset 'IN3_L to Right Mixer Negative Resistor' 'Off'
sset 'IN3_R to Left Mixer Negative Resistor' 'Off'
sset 'IN3_R to Right Mixer Positive Resistor' 'Off'

sset 'Mic PGA' off
sset 'PGA Level' 0

# Disable and clear AGC
sset 'ADCFGA Right Mute' off
sset 'ADCFGA Left Mute' off
sset 'AGC Attack Time' 0
sset 'AGC Decay Time' 0
sset 'AGC Gain Hysteresis' 0
sset 'AGC Hysteresis' 0
sset 'AGC Max PGA' 0
sset 'AGC Noise Debounce' 0
sset 'AGC Noise Threshold' 0
sset 'AGC Signal Debounce' 0
sset 'AGC Target Level' 0
sset 'AGC Left' off
sset 'AGC Right' off

# Turn off High Power output
sset 'HP DAC' off
sset 'HP Driver Gain' 0
sset 'HPL Output Mixer L_DAC' off
sset 'HPR Output Mixer R_DAC' off
sset 'HPL Output Mixer IN1_L' off
sset 'HPR Output Mixer IN1_R' off

#  Turn on the LO DAC
sset 'LO DAC' on

# Turn on both left & right channels
# Turn on AFIN
sset 'LOL Output Mixer L_DAC' on

# Turn on TONEIN
sset 'LOR Output Mixer R_DAC' on
EOF

dbgecho "amixer finished"
prgram="alsa-show.sh"

ALSACTL="alsactl"
if [[ $EUID != 0 ]] ; then
   # This prevents the following error:
   #   No protocol specified
   #   xcb_connection_has_error() returned true
   unset DISPLAY

   ALSACTL="sudo alsactl"
   prgram="$HOME/bin/alsa-show.sh"
else
   prgram="/home/pi/bin/alsa-show.sh"
fi

$ALSACTL store
if [ "$?" -ne 0 ] ; then
    echo "ALSA mixer settings NOT stored."
else
    dbgecho "ALSA mixer successfully stored."
fi

# Display abreviated listing of settings
which $prgram > /dev/null
if [ "$?" -eq 0 ] ; then
    dbgecho "Found $(basename $prgram) in path"
    $prgram
else
    echo "Could not locate $prgram"
fi
