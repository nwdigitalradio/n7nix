#!/bin/bash
#
DEBUG=

# ===== Edit the following to match environment =====

# Radio model number used by HamLib
# List radio model id numbers: rigctl -l
# Radio Model Number 2034 specifies a Kenwood D710 which mostly works for a
#  Kenwood TM-V71a

# Kenwood D710: 2034
# ICom 706 MkIIG: 3011
# ICom 7100: 3070
# ICom 7300: 3073

RADIO_MODEL_ID=3070

DEFAULT_FREQ=7101300

# Serial device for Rig Control
SERIAL_DEVICE="/dev/ttyUSB0"

LOCAL_BINDIR="/usr/local/bin"
RIGCTL="$LOCAL_BINDIR/rigctl"

# ===== end Edit section =====

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function get_vfo_freq

function get_vfo_freq() {

    read_freq=$($RIGCTL -r $SERIAL_DEVICE  -m $RADIO_MODEL_ID f)
}

# ===== function set_vfo_freq
# Arg1: frequency to set

function set_vfo_freq() {

    vfo_freq="$1"
    dbgecho "${FUNCNAME[0]}: freq: $vfo_freq"

    ret_code=1
    to_secs=$SECONDS
    to_time=0
    b_found_error=false

    while [ $ret_code -gt 0 ] && [ $((SECONDS-to_secs)) -lt 5 ] ; do

        # This errors out
        # rigctl -r $SERIAL_DEVICE -m $RADIO_MODEL_ID --vfo F $gw_freq $DATBND

        set_freq_ret=$($RIGCTL -r $SERIAL_DEVICE -m $RADIO_MODEL_ID F $vfo_freq)

        returncode=$?
        if [ ! -z "$set_freq_ret" ] ; then
            ret_code=1
            vfomode_read=$($RIGCTL -r $SERIAL_DEVICE  -m $RADIO_MODEL_ID f)
            errorsetfreq=$set_freq_ret
            errorcode=$returncode
            to_time=$((SECONDS-to_secs))
            b_found_error=true
        else
            ret_code=0
        fi
     done

    # Display some debug data
    if $b_found_error && [ $to_time -gt 3 ] ; then
        vfomode_read=$($RIGCTL -r $SERIAL_DEVICE  -m $RADIO_MODEL_ID v)
        gw_log "RIG CTRL ERROR[$errorcode]: set freq: $vfo_freq, TOut: $to_time, VFO mode=$vfomode_read, error:$errorsetfreq"
    fi

    return $ret_code
}

# ===== main


if [ ! -e $SERIAL_DEVICE ] ; then

    echo "Serial device: $SERIAL_DEVICE does not exist"
    exit 1
fi

set_freq=$DEFAULT_FREQ

if [[ $# -gt 0 ]] ; then
    set_freq=$(( $1 ))
fi

get_vfo_freq

echo " Currently set freq: $read_freq"

echo "Setting frequency to: $set_freq for radio: $RADIO_MODEL_ID"

set_vfo_freq "$set_freq"

get_vfo_freq

echo " Frequency now set to: $read_freq"


