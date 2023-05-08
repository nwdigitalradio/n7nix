#!/bin/bash
#
# set-udrc-both.sh
#
# Configuration for a Kenwood TM-V71a attached to the mDin6 connector on
# a UDRC II HAT.
#
# HD15  is on left channel, direwolf chan 0
# mDin6 is on right channel,  direwolf chan 1
#
# This sets levels for Kenwood & Alinco radios
DEBUG=1
scriptname="`basename $0`"

asoundstate_file="/var/lib/alsa/asound.state"
ALSA_LOG_DIR="$HOME/tmp"
ALSA_LOG_FILE="$ALSA_LOG_DIR/alsa_mixer.log"

# Default to 1200 baud settings for both channels
PCM_LEFT="0.0"
PCM_RIGHT="0.0"
LO_DRIVER_LEFT="-6.0"
LO_DRIVER_RIGHT="3.0"
ADC_LEVEL_LEFT="-9.0"
ADC_LEVEL_RIGHT="-4.0"

# This relates to a DRAWS board ONLY not a UDRC/UDRC II

IN1_L="10 kOhm"
IN1_R="10 kOhm"
IN2_L='Off'
IN2_R='Off'

# A UDRC/UDRC II inputs are hard wired like this:
# DISCOUT Line In 1 Right connector, pin 4
# AFOUT Line In 1 Left connector,  pin 5

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== main

# Check for existence of ALSA log file
if [ ! -d $ALSA_LOG_DIR ] ; then
   mkdir -p $ALSA_LOG_DIR
fi

stateowner=$(stat -c %U $asoundstate_file)
if [ $? -ne 0 ] ; then
   "Command 'alsactl store' will not work, file: $asoundstate_file does not exist"
   exit
fi

# Be sure we're running as root
 if [[ $EUID != 0 ]] ; then
   echo "Command 'alsactl store' will not work unless you are root"
fi

#  Set input and output levels for Alinco & Kenwood radio

RADIO="TM-71 & Alinco DR-235"
echo -e "\n--------\n" >> $ALSA_LOG_FILE
echo "$(date): Radio: $RADIO set from $scriptname" | tee -a $ALSA_LOG_FILE

amixer -c udrc -s << EOF  >> $ALSA_LOG_FILE
sset 'PCM' "${PCM_LEFT}dB,${PCM_RIGHT}dB"
sset 'LO Driver Gain' "${LO_DRIVER_LEFT}dB,${LO_DRIVER_RIGHT}dB"
sset 'ADC Level' ${ADC_LEVEL_LEFT}dB,${ADC_LEVEL_RIGHT}dB

sset 'IN1_L to Left Mixer Positive Resistor' "$IN1_L"
sset 'IN1_R to Right Mixer Positive Resistor' "$IN1_R"
sset 'IN2_L to Left Mixer Positive Resistor' "$IN2_L"
sset 'IN2_R to Right Mixer Positive Resistor' "$IN2_R"

# Set default input and output levels
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

# Turn off Head Phone output
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
# This should be ignored for the original UDRC
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
