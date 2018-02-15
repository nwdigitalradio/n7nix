#!/bin/bash
#
# set-udrc-alinco.sh
#
# - Assumes using Alinco radio attached to mDin6 connector
#
# HD15  is on right channel, direwolf chan 0
# mDin6 is on left channel,  direwolf chan 1
#
# This just sets levels for Alinco radio

amixer -c udrc -s << EOF
#  Set input and output levels for Alinco radio
sset 'ADC Level' -5.0dB
sset 'LO Driver Gain' -6.0dB
sset 'PCM' -8.0dB

#  Turn on the LO DAC
sset 'LO DAC' on

#  Turn on AFIN, Line out left
sset 'LOL Output Mixer L_DAC' on

#  Turn on TONEIN
#  Ignore this for an original UDRC
#sset 'LOR Output Mixer R_DAC' on
EOF
alsactl store
