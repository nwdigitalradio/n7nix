#!/bin/bash
#
# both_baud.sh
#
# Add configuration to allow both 1200 & 9600 baud when using an mDin6
# Y cable and both ports on a DRAWS hat.
#
# - Change ax25/port.conf
# - Add entries to ax25/ax25d.conf
# - Change call sign in ax25/axports
# - Change in direwolf.conf
#   - Verify there is a single ARATE entries one for each audio DEVICE
#   - ARATE sample-rate applies to the most recent ADEVICEn command
#   - ADEVICE = ADEVICE0

scriptname="`basename $0`"

AX25_CFGDIR="/usr/local/etc/ax25"
PORT_CFG_FILE="$AX25_CFGDIR/port.conf"
AX25D_CFG_FILE="$AX25_CFGDIR/ax25d.conf"

DIREWOLF_CFGFILE="/etc/direwolf.conf"

# ===== function get_callsign
function get_callsign() {
    filename="$AX25D_CFG_FILE"
    echo
    echo " == Call signs in $filename =="

    # Squish all spaces
#    grep -v "^#" $filename | tr -s '[[:space:]]' | cut -f2 -d' '
    CALLSIGN=$(grep -v "^#" /etc/ax25/ax25d.conf | tr -s '[[:space:]]' | grep "^\[" | cut -f1 -d' ' | sed 's/\[//g' | cut -d'-' -f1 | head -n1)
}

# ===== function set_port_conf file
# Set baud rate & receive_out disc/audio for both ports

# [port0]
# speed=9600
# receive_out=disc
#
# [port1]
# speed=1200
# receive_out=disc

function set_port_conf() {

    sed -in '/\[port0\]/,/\[/ s/^speed=.*/speed=9600/' $PORT_CFG_FILE
    sed -in '/\[port0\]/,/\[/ s/^receive_out=.*/receive_out=disc/' $PORT_CFG_FILE

    sed -in '/\[port1\]/,/\[/ s/^speed=.*/speed=1200/' $PORT_CFG_FILE
    sed -in '/\[port1\]/,/\[/ s/^receive_out=.*/receive_out=disc/' $PORT_CFG_FILE

    # debug
    grep -i "speed" $PORT_CFG_FILE
    grep -i "receive_out" $PORT_CFG_FILE
}

# ===== function set_ax25d_conf
# Add the second port, ie. other side of sound device

# [CALLSIGN-10 VIA udr1]
# NOCALL   * * * * * *  L
# default  * * * * * *  - rmsgw /usr/local/bin/rmsgw rmsgw -P %d %U
# #
# [CALLSIGN VIA udr1]
# NOCALL   * * * * * *  L
# default  * * * * * *  - pi /usr/local/bin/wl2kax25d wl2kax25d -c %U -a %d

function set_ax25d_conf() {
    get_callsign
    echo "DEBUG: using CALLSIGN: $CALLSIGN"

    left_entry_cnt=$(grep  "$CALLSIGN" /etc/ax25/ax25d.conf | grep -c "udr0")
    right_entry_cnt=$(grep  "$CALLSIGN" /etc/ax25/ax25d.conf | grep -c "udr1")
}

# ===== main

# ===== Change file: /etc/ax25/port.conf
#
set_port_conf

# ===== Change file: /etc/ax25/ax25d.conf

set_ax25d_conf


# ===== /etc/direwolf.conf changes
# Should be only 1 arate entery per audio device.
grep -i "^arate " /etc/direwolf.conf

# Do the ptt gpio's need to be different?
grep -i "^ptt gpio" /etc/direwolf.conf