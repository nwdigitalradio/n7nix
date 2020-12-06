#!/bin/bash
#
# setalsa-off.sh
#
# Turn off & down as many controls as possible

DEBUG=
LISTEN_ONLY=

scriptname="`basename $0`"

asoundstate_file="/var/lib/alsa/asound.state"

ALSA_LOG_DIR="$HOME/tmp"
ALSA_LOG_FILE="$ALSA_LOG_DIR/alsa_mixer.log"
IN1_L="Off"
IN1_R="Off"
IN2_L="Off"
IN2_R="Off"

PCM_LEFT="-63.5"
PCM_RIGHT="-63.5"
LO_DRIVER_LEFT="-6.0"
LO_DRIVER_RIGHT="-6.0"
ADC_LEVEL_LEFT="-12.0"
ADC_LEVEL_RIGHT="-12.0"

PTM_PL="P1"
PTM_PR="P1"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function listen_only
function set_listen_only() {
amixer -c udrc -s << EOF >> $ALSA_LOG_FILE
sset 'PCM' "${PCM_LEFT}dB,${PCM_RIGHT}dB"
sset 'LO Driver Gain' "${LO_DRIVER_LEFT}dB,${LO_DRIVER_RIGHT}dB"

sset 'DAC Left Playback PowerTune'  $PTM_PL
sset 'DAC Right Playback PowerTune' $PTM_PR

# Turn off both left & right channel outputs
# Makes DAC listen ONLY
sset 'LOL Output Mixer L_DAC' off
sset 'LOR Output Mixer R_DAC' off

EOF
}

# ===== function dac_off
function set_dac_off() {

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

# Turn off both left & right channel outputs
# Makes DAC listen ONLY
sset 'LOL Output Mixer L_DAC' off
sset 'LOR Output Mixer R_DAC' off

EOF
}

# ===== main

# SET LISTEN_ONLY flag if there any command line args
if (( $# != 0 )) ; then
    LISTEN_ONLY=1
fi

if [ -z $LISTEN_ONLY ] ; then
    set_dac_off
else
    set_listen_only
fi

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
