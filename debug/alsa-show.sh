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
# if there are no args default to out put a message beacon
if [[ $# -ne 0 ]] ; then
   CARD="$1"
   echo "Setting sound card to: $CARD"
fi

# ===== function dbgecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function display_ctrl
function display_ctrl() {
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

control="PCM"
display_ctrl "$control"
printf "%s\t        L:%s, R:%s\n" "$control" $CTRL_VAL_L $CTRL_VAL_R

control="ADC Level"
display_ctrl "$control"
printf "%s\tL:%s, R:%s\n" "$control" $CTRL_VAL_L $CTRL_VAL_R

control="LO Driver Gain"
display_ctrl "$control"
printf "%s  L:%s, R:%s\n" "$control" $CTRL_VAL_L $CTRL_VAL_R

