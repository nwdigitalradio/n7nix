#!/bin/bash

PORT_CFG_FILE="/usr/local/etc/ax25/port.conf"

# ===== function is_udrc

function is_udrc() {

    (/usr/bin/aplay -l) | (/usr/bin/grep --quiet -i "udrc")
    return $?
}

# ===== function is_dinah

function is_dinah() {

    /usr/bin/aplay -l | /usr/bin/grep --quiet "USB Audio Device"
    return $?
}

# ===== main

sndcard_cnt=0

if is_udrc ; then
    echo "Found a UDRC"
    ((sndcard_cnt+=1))
fi

if is_dinah ; then
    echo "Found a DINAH"
    ((sndcard_cnt+=1))
fi

if is_udrc && is_dinah  ; then
    # If both sound devices are installed default to DINAH
    DEVICE="dinah"
    echo "Found both sound devices"
else
    echo "Found $sndcard_cnt sound cards"
fi

if [ -f $PORT_CFG_FILE ] ; then
    grep -q -i "^Device" $PORT_CFG_FILE
    if [ $? -eq 0  ] ; then
#        DEVICE=$(grep -i "^Device" $PORT_CFG_FILE)
	DEVICE=$(grep -m1 "^Device=" $PORT_CFG_FILE | cut -f2 -d'=')
	echo "Device set in port config file is: $DEVICE"
    else
	echo "Device parameter NOT set in $PORT_CFG_FILE"
    fi
else
    echo "No port config file found: $PORT_CFG_FILE"
    DEVICE="dinah"
fi


