#!/bin/bash
#
# setalsa-tmv71a.sh
#
# Configuration for a Kenwood TM-V71a attached to Left or Right channel
# on a DRAWS HAT
#
# mDin6 connector on left channel,  direwolf chan 0
# mDin6 connector on right channel, direwolf chan 1
#

asoundstate_file="/var/lib/alsa/asound.state"
AX25_CFGDIR="/usr/local/etc/ax25"
PORT_CFG_FILE="$AX25_CFGDIR/port.conf"

# Default to 1200 baud settings for both channels
PCM_LEFT="-2.0"
PCM_RIGHT="-2.0"
LO_DRIVER_LEFT="0.0"
LO_DRIVER_RIGHT="0.0"
ADC_LEVEL_LEFT="0.0"
ADC_LEVEL_RIGHT="0.0"

IN1_L='Off'
IN1_R='Off'
IN2_L="10 kOhm"
IN2_R="10 kOhm"


# Check if no port config file found
if [ ! -f $PORT_CFG_FILE ] ; then
    echo "No port config file: $PORT_CFG_FILE found, using defaults."

    if [[ $EUID == 0 ]] ; then
        echo "Must NOT be root"
        exit 1
    fi
    # This will not work when run as root
    sudo cp $HOME/n7nix/ax25/port.conf $PORT_CFG_FILE
else
    # Set left channel parameters
    portcfg="port0"
    PORTSPEED_LEFT=$(sed -n "/\[$portcfg\]/,/\[/p" $PORT_CFG_FILE | grep -i "^speed" | cut -f2 -d'=')
    RECVSIG_LEFT=$(sed -n "/\[$portcfg\]/,/\[/p" $PORT_CFG_FILE | grep -i "^receive_out" | cut -f2 -d'=')
    if [ "$RECVSIG" == "disc" ] ; then
        # Set variables for discriminator signal
        PCM_LEFT="0.0"
        LO_DRIVER_LEFT="3.0"
        ADC_LEVEL_LEFT="-4.0"
        IN1_L='10 kOhm'
        IN2_L="Off"
    fi

    # Set right channel parameters
    portcfg="port1"
    PORTSPEED_RIGHT=$(sed -n "/\[$portcfg\]/,/\[/p" $PORT_CFG_FILE | grep -i "^speed" | cut -f2 -d'=')
    RECVSIG_RIGHT=$(sed -n "/\[$portcfg\]/,/\[/p" $PORT_CFG_FILE | grep -i "^receive_out" | cut -f2 -d'=')
    if [ "$RECVSIG" == "disc" ] ; then
        # Set variables for discriminatior signal
        PCM_RIGHT="0.0"
        LO_DRIVER_RIGHT="3.0"
        ADC_LEVEL_RIGHT="-4.0"
        IN1_R='10 kOhm'
        IN2_R="Off"
    fi
fi

stateowner=$(stat -c %U $asoundstate_file)
if [ $? -ne 0 ] ; then
   "Command 'alsactl store' will not work, file: $asoundstate_file does not exist"
   exit
fi

# IN1 Discriminator output (FM function only, not all radios, 9600 baud packet)
# IN2 Compensated receive audio (all radios, 1200 baud and slower packet)

# Test new method!
echo "== DEBUG =="
echo "PCM: $PCM_LEFT, $PCM_RIGHT"
echo "LO Driver Gain: ${LO_DRIVER_LEFT}dB,${LO_DRIVER_RIGHT}dB"
echo "ADC Level: ${ADC_LEVEL_LEFT}dB,${ADC_LEVEL_RIGHT}dB"
echo "IN1: $IN1_L, $IN1_R"
echo "IN2: $IN2_L, $IN2_R"
echo

    amixer -c udrc -s << EOF
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

ALSACTL="alsactl"
if [[ $EUID != 0 ]] ; then
   ALSACTL="sudo alsactl"
fi

$ALSACTL store
