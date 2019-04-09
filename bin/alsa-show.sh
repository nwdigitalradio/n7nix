#!/bin/bash
#
# Display alsa controls that are interesting
# Uncomment this statement for debug echos
# DEBUG=1

scriptname="`basename $0`"

# Default card name
CARD="udrc"

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

# ===== function display_ctrl

function display_ctrl() {
    alsa_ctrl="$1"
    CTRL_STR="$(amixer -c $CARD get \""$alsa_ctrl"\")"
#    dbgecho "$alsa_ctrl: $CTRL_STR"
    CTRL_VAL=$(amixer -c $CARD get \""$alsa_ctrl"\" | grep -i -m 1 "Item0:" | cut -d ':' -f2)
    # Remove preceeding white space
    CTRL_VAL="$(sed -e 's/^[[:space:]]*//' <<<"$CTRL_VAL")"
    # Remove surrounding quotes
    CTRL_VAL=${CTRL_VAL%\'}
    CTRL_VAL=${CTRL_VAL#\'}
}

# ===== Display program help info

function usage () {
	(
	echo "Usage: $scriptname [-c card_name][-d][-h]"
        echo "    -c card_name, default=udrc"
        echo "    -d switch to turn on verbose debug display"
        echo "    -h display this message."
        echo
	) 1>&2
	exit 1
}

# ===== main

# amixer -c $CARD get 'ADC Level'
# amixer -c $CARD get 'LO Driver Gain'
CONTROL_LIST="'ADC Level' 'LO Drive Gain' 'PCM'"

# parse any command line options
while [[ $# -gt 0 ]] ; do

    key="$1"
    case $key in
        -d)
            echo "Turning on debug"
            DEBUG=1
        ;;
        -c)

            CARD="$2"
            shift # past value
            echo "Setting card name to $CARD"
        ;;
        -h)
            usage
            exit 0
        ;;
        *)
            echo "Undefined argument: $key"
            usage
            exit 1
        ;;
    esac
    shift # past argument or value
done

echo " ===== ALSA Controls for Radio Transmit ====="

control="LO Driver Gain"
audio_display_ctrl "$control"
printf "%s  L:%s\tR:%s\n" "$control" $CTRL_VAL_L $CTRL_VAL_R

control="PCM"
audio_display_ctrl "$control"
printf "%s\t        L:%s\tR:%s\n" "$control" $CTRL_VAL_L $CTRL_VAL_R

# Running udrc-dkms version 1.0.5 or later
alsactrl_count=$(amixer -c $CARD scontrols | wc -l)

if (( alsactrl_count >= 44 )) ; then
    control="DAC Left Playback PowerTune"
    display_ctrl "$control"
    CTRL_PTM_L="$CTRL_VAL"

    control="DAC Right Playback PowerTune"
    display_ctrl "$control"
    CTRL_PTM_R="$CTRL_VAL"
    # Shorten control string for display
    control="DAC Playback PT"
    printf "%s\tL:[%s]\tR:[%s]\n" "$control" "$CTRL_PTM_L" "$CTRL_PTM_R"

    control="LO Playback Common Mode"
    display_ctrl "$control"
    # echo "DEBUG: CTRL_VAL: $CTRL_VAL"
    # Shorten control string for display
    control="LO Playback CM"
    printf "%s\t[%s]\n" "$control" "$CTRL_VAL"
fi


echo
echo " ===== ALSA Controls for Radio Receive ====="

control="ADC Level"
audio_display_ctrl "$control"
printf "%s\tL:%s\tR:%s\n" "$control" $CTRL_VAL_L $CTRL_VAL_R

# Note: only Displaying Positive resistors for IN1 IN2 L/R
# The Micor radio needs settings for:
#  'IN1_L to Right Mixer Negative Resistor'

control="IN1_L to Left Mixer Positive Resistor"
display_ctrl "$control"
CTRL_IN1_L="$CTRL_VAL"

control="IN1_R to Right Mixer Positive Resistor"
display_ctrl "$control"
CTRL_IN1_R="$CTRL_VAL"

control="IN2_L to Left Mixer Positive Resistor"
display_ctrl "$control"
CTRL_IN2_L="$CTRL_VAL"

control="IN2_R to Right Mixer Positive Resistor"
display_ctrl "$control"
CTRL_IN2_R="$CTRL_VAL"

control="CM_L to Left Mixer Negative Resistor"
display_ctrl "$control"
CTRL_CM_L="$CTRL_VAL"

control="CM_R to Right Mixer Negative Resistor"
display_ctrl "$control"
CTRL_CM_R="$CTRL_VAL"

control="IN1"
strlen=${#CTRL_IN1_L}
if ((strlen < 4)) ; then
    printf "%s\t\tL:[%s]\t\tR:[%s]\n" "$control" "$CTRL_IN1_L" "$CTRL_IN1_R"
else
    printf "%s\t\tL:[%s]\tR:[%s]\n" "$control" "$CTRL_IN1_L" "$CTRL_IN1_R"
fi

control="IN2"
strlen=${#CTRL_IN2_L}
if ((strlen < 4)) ; then
    printf "%s\t\tL:[%s]\t\tR:[%s]\n" "$control" "$CTRL_IN2_L" "$CTRL_IN2_R"
else
    printf "%s\t\tL:[%s]\tR:[%s]\n" "$control" "$CTRL_IN2_L" "$CTRL_IN2_R"
fi

control="CM"
strlen=${#CTRL_CM_L}
if ((strlen < 4)) ; then
    printf "%s\t\tL:[%s]\t\tR:[%s]\n" "$control" "$CTRL_CM_L" "$CTRL_CM_R"
else
    printf "%s\t\tL:[%s]\tR:[%s]\n" "$control" "$CTRL_CM_L" "$CTRL_CM_R"
fi


if [ ! -z "$DEBUG" ] ; then
    control="IN1_L to Left Mixer Positive Resistor"
    display_ctrl "$control"
    CTRL_IN1_L="$CTRL_VAL"
    printf "%s\t%s\n" "$control" "$CTRL_VAL"

    control="IN1_R to Right Mixer Positive Resistor"
    display_ctrl "$control"
    CTRL_IN1_R="$CTRL_VAL"
    printf "%s\t%s\n" "$control" "$CTRL_VAL"

    control="IN2_L to Left Mixer Positive Resistor"
    display_ctrl "$control"
    CTRL_IN2_L="$CTRL_VAL"
    printf "%s\t%s\n" "$control" $CTRL_VAL

    control="IN2_R to Right Mixer Positive Resistor"
    display_ctrl "$control"
    CTRL_IN2_R="$CTRL_VAL"
    printf "%s\t%s\n" "$control" $CTRL_VAL

    alsa_ctrl='LO Playback Common Mode'
    amixer -c $CARD get \""$alsa_ctrl"\"
    alsa_ctrl='DAC Left Playback PowerTune'
    amixer -c $CARD get \""$alsa_ctrl"\"
    alsa_ctrl='DAC Right Playback PowerTune'
    amixer -c $CARD get \""$alsa_ctrl"\"
fi
