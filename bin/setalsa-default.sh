#!/bin/bash
#
# set-udrc-both.sh
#
# - Assumes:
#   - Alinco radio attached to HD15 connector
#   - Kenwood radio attached to mDin6 connector
#
# HD15  is on right channel, Direwolf chan 0
# mDin6 is on left channel,  Direwolf chan 1
#
#      sset left chan, right chan
#  ie, sset Kenwood,   Alinco
# sset 'PCM'          0.0dB,0.0dB
# sset 'ADC Level'   -2.0dB,-2.0.0dB
# sset 'LO Driver Gain' 0dB,11.0dB

MODE_9600_ENABLE=false

asoundstate_file="/var/lib/alsa/asound.state"
stateowner=$(stat -c %U $asoundstate_file)
if [ $? -ne 0 ] ; then
   "Command 'alsactl store' will not work, file: $asoundstate_file does not exist"
   exit
fi

# Be sure we're running as root
 if [[ $EUID != 0 ]] ; then
   echo "Command 'alsactl store' will not work unless you are root"
fi

amixer -c udrc -s << EOF
#  Set input and output levels for both Kenwood & Alinco radios
sset 'PCM' 0.0dB,0.0dB
sset 'ADC Level' 0.0dB,0.0.0dB
sset 'LO Driver Gain' 0.0dB,0.0dB

# Everything after this is common to both radios

sset 'CM_L to Left Mixer Negative Resistor' '10 kOhm'
sset 'CM_R to Right Mixer Negative Resistor' '10 kOhm'

# IN1 Discriminator output (FM function only, not all radios, 9600 baud packet)
# IN2 Receive audio (all radios, 1200 baud packet)

if [ "$MODE_9600_ENABLE" = "true" ] ; then

    # For 9600 baud packet only
    # Turn AFOUT off & DISCOUT on
    # ie. Receive audio off & discriminator output on

    sset 'IN1_L to Left Mixer Positive Resistor' '10 kOhm'
    sset 'IN1_R to Right Mixer Positive Resistor' '10 kOhm'
    sset 'IN2_L to Left Mixer Positive Resistor' 'Off'
    sset 'IN2_R to Right Mixer Positive Resistor' 'Off'

else
    # Default mode, for HF & 1200 baud packet
    # Turn AFOUT on & DISCOUT off
    # ie. Receive audio on & discriminator off

    sset 'IN1_L to Left Mixer Positive Resistor' 'Off'
    sset 'IN1_R to Right Mixer Positive Resistor' 'Off'
    sset 'IN2_L to Left Mixer Positive Resistor' '10 kOhm'
    sset 'IN2_R to Right Mixer Positive Resistor' '10 kOhm'
fi

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
alsactl store
