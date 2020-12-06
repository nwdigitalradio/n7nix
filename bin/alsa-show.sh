#!/bin/bash
#
# Display alsa controls that are interesting
# Uncomment this statement for debug echos
#DEBUG=1
bverbose=false

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

# ===== function display_dac

function display_dac() {
    alsa_ctrl="$1"
    CTRL_STR="$(amixer -c $CARD get \""$alsa_ctrl"\")"

    CTRL_VAL=$(amixer -c $CARD get \""$alsa_ctrl"\" | grep -i -m 1 "Mono: Playback" | cut -d ':' -f2)

    # Remove preceeding white space
    CTRL_VAL="$(sed -e 's/^[[:space:]]*//' <<<"$CTRL_VAL")"
    dbgecho "display_dac: $alsa_ctrl: $CTRL_VAL"
}

# ===== function display_all
# Display all ALSA control values
function display_all() {

    echo " ==== Display all $(amixer -c udrc scontrols | wc -l) controls ===="

    control_list="$(amixer -c udrc scontrols)"

#    for alsa_ctrl in $control_list  ; do
#        echo "Control = $alsa_ctrl"
#    done

while read control; do
    ctrl_name=$(echo $control | cut -f2 -d"'")
#    echo "Control = $control, short name: $ctrl_name"

    CTRL_STR="$(amixer -c $CARD get \""$ctrl_name"\")"

    echo " == Control Name: $ctrl_name ==="
    echo " $CTRL_STR"
    echo

done <<< $control_list
}

# ===== Display program help info

function usage () {
	(
	echo "Usage: $scriptname [-c card_name][-d][-h]"
        echo "    -a dump all alsa control values"
        echo "    -c card_name, default=udrc"
        echo "    -v turn on verbose display"
        echo "    -d turn on debug display"
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
        -v)
            echo "Turning on verbose"
            bverbose=true
        ;;
        -a)
            echo
            display_all
            exit 0
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
    printf "%s\tL:[%s]\t\tR:[%s]\n" "$control" "$CTRL_PTM_L" "$CTRL_PTM_R"

    control="LO Playback Common Mode"
    display_ctrl "$control"
    # echo "DEBUG: CTRL_VAL: $CTRL_VAL"
    # Shorten control string for display
    control="LO Playback CM"
    printf "%s\t[%s]\n" "$control" "$CTRL_VAL"
fi

# If output mixers are off then display that

control="LOL Output Mixer L_DAC"
display_dac "$control"
CTRL_LOL_OUTPUT_MIXER_L="$CTRL_VAL"

control="LOR Output Mixer R_DAC"
display_dac "$control"
CTRL_LOR_OUTPUT_MIXER_R="$CTRL_VAL"

# Find out if either of the mixer outputs have been turned off

CTRL_LOL_OUTPUT_M=$(echo "$CTRL_LOL_OUTPUT_MIXER_L" | cut -d'[' -f2 | cut -d ']' -f1)
CTRL_LOR_OUTPUT_M=$(echo "$CTRL_LOR_OUTPUT_MIXER_R" | cut -d'[' -f2 | cut -d ']' -f1)

if [ "$CTRL_LOL_OUTPUT_M" = "off" ] || [ "$CTRL_LOR_OUTPUT_M" = "off" ] ; then
    control="Output Mixer"
    dbgecho " == before printf: $control: L:[$CTRL_LOL_OUTPUT_M], R:[$CTRL_LOR_OUTPUT_M]"
#    printf "%s    L:%s R:%s\n" "$control" "$CTRL_LOL_OUTPUT_MIXER_L" "$CTRL_LOR_OUTPUT_MIXER_R"
    printf "%s    L:[%s]\t\tR:[%s]\n" "$control" "$CTRL_LOL_OUTPUT_M" "$CTRL_LOR_OUTPUT_M"
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

if [ "$bverbose" == true ] ; then

    control="IN1_L to Right Mixer Negative Resistor"
    display_ctrl "$control"
    CTRL_IN1_L_RNEG="$CTRL_VAL"

    control="IN1_R to Left Mixer Positive Resistor"
    display_ctrl "$control"
    CTRL_IN1_R_LPOS="$CTRL_VAL"

    control="IN2_L to Right Mixer Positive Resistor"
    display_ctrl "$control"
    CTRL_IN2_L_RPOS="$CTRL_VAL"

    control="IN2_R to Left Mixer Negative Resistor"
    display_ctrl "$control"
    CTRL_IN2_R_LNEG="$CTRL_VAL"

    control="IN1 to Neg"
    strlen=${#CTRL_IN1_L_RNEG}
    if ((strlen < 4)) ; then
        printf "%s\tL:[%s]\t\tR:[%s]\n" "$control" "$CTRL_IN1_L_RNEG" "$CTRL_IN1_R_LPOS"
    else
        printf "%s\tL:[%s]\tR:[%s]\n" "$control" "$CTRL_IN1_L_RNEG" "$CTRL_IN1_R_LPOS"
    fi

    control="IN2 to Neg"
    strlen=${#CTRL_IN2_L_RNEG}
    if ((strlen < 4)) ; then
        printf "%s\tL:[%s]\t\tR:[%s]\n" "$control" "$CTRL_IN2_L_RPOS" "$CTRL_IN2_R_LNEG"
    else
        printf "%s\tL:[%s]\tR:[%s]\n" "$control" "$CTRL_IN2_L_RPOS" "$CTRL_IN2_R_LNEG"
    fi
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
