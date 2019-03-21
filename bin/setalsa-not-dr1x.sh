#!/bin/bash
# UDRC II for DStar on a Micor repeater
# Note not a DR-1x DStar Repeater
# From KU7M 03/2019

amixer -c udrc -s << EOF
#  Set input and output levels to 0dB
sset 'ADC Level' -2.0dB
sset 'LO Driver Gain' 0dB
sset 'PCM' 0.0dB

#  Turn on AFOUT
sset 'IN1_L to Right Mixer Negative Resistor' '10 kOhm'

#  Turn on DISCOUT
#  Increasing to 20 kOhms for Micor repeater output
sset 'IN1_R to Right Mixer Positive Resistor' '20 kOhm'

#  Turn off unnecessary pins
sset 'CM_L to Left Mixer Negative Resistor' 'Off'
sset 'CM_R to Right Mixer Negative Resistor' 'Off'

sset 'IN1_L to Right Mixer Positive Resistor' 'Off'
sset 'IN1_L to Left Mixer Positive Resistor' 'Off'

sset 'IN2_L to Left Mixer Positive Resistor' 'Off'
sset 'IN2_L to Right Mixer Positive Resistor' 'Off'
sset 'IN2_R to Left Mixer Negative Resistor' 'Off'
sset 'IN2_R to Right Mixer Positive Resistor' 'Off'

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

#  Turn on AFIN
sset 'LOL Output Mixer L_DAC' on

#  Turn on TONEIN
sset 'LOR Output Mixer R_DAC' on
EOF
alsactl store
