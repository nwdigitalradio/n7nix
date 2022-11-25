#!/bin/bash

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

