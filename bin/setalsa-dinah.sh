#!/bin/bash
#
# setalsa-dinah.sh
DEBUG=

# Sound card device name is actually 'USB Audio Device'
CARD="Device"
RADIO="Generic"
scriptname="`basename $0`"

ALSA_LOG_DIR="$HOME/tmp"
ALSA_LOG_FILE="$ALSA_LOG_DIR/alsa_mixer.log"

# Only Line out left channel (LOL) is used
SPEAKER_LEFT="-19.0"
SPEAKER_RIGHT="-19.0"
# Mic is only mono
MIC="-23.0"
AGC="off"

# ===== function dbgecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function dinah_ audio_display_ctrl

function dinah_audio_display_ctrl() {
   alsa_ctrl="$1"
   PCM_STR_L="$(amixer -c $CARD get \""$alsa_ctrl"\" | grep -i "Front Left:" | cut -d '[' -f3)"
#   dbgecho "$alsa_ctrl: $PCM_STR_L"

   PCM_STR_R="$(amixer -c $CARD get \""$alsa_ctrl"\" | grep -i "Front Right:" | cut -d '[' -f3)"
#   dbgecho "$alsa_ctrl: $PCM_STR_R"

    # Remove trailing white space
    CTRL_VAL_L="$(echo -e ${PCM_STR_L} | sed -e 's/[[:space:]]*$//')"
    CTRL_VAL_R="$(echo -e ${PCM_STR_R} | sed -e 's/[[:space:]]*$//')"

    # Remove trailing right square bracket
    CTRL_VAL_L=${CTRL_VAL_L%?}
    CTRL_VAL_R=${CTRL_VAL_R%]}
}

# ===== function dinah_display_ctrl_mic

function dinah_display_ctrl_mic() {
    alsa_ctrl="$1"
    # DEBUG only
    # CTRL_STR="$(amixer -c $CARD get \""$alsa_ctrl"\")"
    # dbgecho "$alsa_ctrl: $CTRL_STR"

    CTRL_VAL=$(amixer -c $CARD get \""$alsa_ctrl"\" | grep -i -m 1 "Mono:" | cut -d ':' -f2 | cut -d '[' -f3)

    # Remove trailing white space
    CTRL_VAL="$(echo -e ${CTRL_VAL} | sed -e 's/[[:space:]]*$//')"
    # Remove trailing right square bracket
    CTRL_VAL=${CTRL_VAL%\]}
}

# ===== function dinah_display_ctrl_agc

function dinah_display_ctrl_agc() {
    alsa_ctrl="$1"
    # DEBUG only
    # CTRL_STR="$(amixer -c $CARD get \""$alsa_ctrl"\")"
    # dbgecho "$alsa_ctrl: $CTRL_STR"

    CTRL_VAL=$(amixer -c $CARD get \""$alsa_ctrl"\" | grep -i -m 1 "Mono:" | cut -d '[' -f2)
    # Remove preceeding white space
    CTRL_VAL="$(sed -e 's/^[[:space:]]*//' <<<"$CTRL_VAL")"
    # Remove trailing right square bracket
    CTRL_VAL=${CTRL_VAL%\]}
}

# ===== function usb_display_alsa
function usb_display_alsa() {

control="Speaker"
dinah_audio_display_ctrl "$control"
printf "%s\t\t\tL:%s\tR:%s\n" "$control" $CTRL_VAL_L $CTRL_VAL_R

control="Mic"
dinah_display_ctrl_mic "$control"
printf "%s\t\t\t%s\n" "$control" $CTRL_VAL

control="Auto Gain Control"
dinah_display_ctrl_agc "$control"
printf "%s\t%s\n" "$control" $CTRL_VAL


}

# ===== main

echo "$(date): Radio: $RADIO set from $scriptname" | tee -a $ALSA_LOG_FILE

# sset 'Auto Gain Control' ${AGC}dB
amixer -c $CARD -s << EOF >> $ALSA_LOG_FILE
sset 'Speaker' "${SPEAKER_LEFT}dB,${SPEAKER_RIGHT}dB" unmute
sset 'Mic' "${MIC}dB" unmute
sset 'Auto Gain Control' ${AGC}
EOF
retcode="$?"
if [ "$retcode" -ne 0 ] ; then
    echo "ERROR setting ALSA settings with amixer, check log file: $ALSA_LOG_FILE"
fi

usb_display_alsa
