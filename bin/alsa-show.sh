#!/bin/bash
# Display alsa controls that are interesting
# Uncomment this statement for debug echos
# DEBUG=1

# Default card name
CARD="udrc"

# amixer -c $CARD get 'ADC Level'
#amixer -c $CARD get 'LO Driver Gain'
CONTROL_LIST="'ADC Level''LO Drive Gain' 'PCM'"

# parse any command line options
# arg1 allows setting the CARD, default is "udrc"
if [[ $# -ne 0 ]] ; then
   CARD="$1"
   echo "Setting sound card to: $CARD"
fi

# ===== function dbgecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function audio_display_ctrl

function audio_display_ctrl() {
   alsa_ctrl="$1"
   PCM_STR="$(amixer -c $CARD get \""$alsa_ctrl"\" | grep -i "Simple mixer control")"
   dbgecho "$alsa_ctrl: $PCM_STR"
   PCM_VAL=$(amixer -c $CARD get \""$alsa_ctrl"\" | grep -i -m 1 "db")
   CTRL_VAL_L=${PCM_VAL##* }
   dbgecho "$alsa_ctrl: Left $PCM_VAL"
   PCM_VAL=$(amixer -c $CARD get \""$alsa_ctrl"\" | grep -i -m 2 "db" | tail -n 1 | cut -d ' ' -f5-)
   CTRL_VAL_R=${PCM_VAL##* }
   dbgecho "$alsa_ctrl: Right $PCM_VAL"
}

# ===== function input_display_ctrl

function input_display_ctrl() {
    alsa_ctrl="$1"
    CTRL_STR="$(amixer -c $CARD get \""$alsa_ctrl"\")"
    dbgecho "$alsa_ctrl: $CTRL_STR"
    CTRL_VAL=$(amixer -c $CARD get \""$alsa_ctrl"\" | grep -i -m 1 "Item0:" | cut -d ':' -f2)
    # Remove preceeding white space
    CTRL_VAL="$(sed -e 's/^[[:space:]]*//' <<<"$CTRL_VAL")"
    # Remove surrounding quotes
    CTRL_VAL=${CTRL_VAL%\'}
    CTRL_VAL=${CTRL_VAL#\'}
}

control="PCM"
audio_display_ctrl "$control"
printf "%s\t        L:%s\tR:%s\n" "$control" $CTRL_VAL_L $CTRL_VAL_R

control="ADC Level"
audio_display_ctrl "$control"
printf "%s\tL:%s\tR:%s\n" "$control" $CTRL_VAL_L $CTRL_VAL_R

control="LO Driver Gain"
audio_display_ctrl "$control"
printf "%s  L:%s\tR:%s\n" "$control" $CTRL_VAL_L $CTRL_VAL_R

control="IN1_L to Left Mixer Positive Resistor"
input_display_ctrl "$control"
printf "%s\t%s\n" "$control" "$CTRL_VAL"

control="IN1_R to Right Mixer Positive Resistor"
input_display_ctrl "$control"
printf "%s\t%s\n" "$control" "$CTRL_VAL"

control="IN2_L to Left Mixer Positive Resistor"
input_display_ctrl "$control"
printf "%s\t%s\n" "$control" $CTRL_VAL

control="IN2_R to Right Mixer Positive Resistor"
input_display_ctrl "$control"
printf "%s\t%s\n" "$control" $CTRL_VAL
