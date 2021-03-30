#!/bin/bash
#
# usb_ptt.sh
#
# Using C-Media HID name turn CM108 gpio 3 on/off
#

# ===== usb_hid_dev
# Find HID raw device name for C-Media

usb_hid_dev() {
    found_hid_dev=false
    FILES=/dev/hidraw*

    for f in $FILES ; do
        HID_FILE=${f##*/}
        if [ -e /sys/class/hidraw/${HID_FILE}/device/uevent ] ; then
            DEVICE="$(cat /sys/class/hidraw/${HID_FILE}/device/uevent | grep HID_NAME | cut -d '=' -f2)"
	    grep -q "C-Media" <<< $DEVICE
            if [ $? -eq 0 ] ; then
                echo "Using HID device: $HID_FILE"
                found_hid_dev=true
	        break
#               printf "%s \t %s\n" $HID_FILE "$DEVICE"
            fi
        fi
    done
    if [ $found_hid_dev = false ] ; then
        echo "ERROR: Could not find HID device C-Media"
	exit
    fi
}

#  Build a packet for CM108 HID to turn GPIO bit on or off.
#  Packet is 4 bytes, preceded by a 'report number' byte
#  0x00 report number
#  Write data packet (from CM108 documentation)
#  byte 0: 00xx xxxx     Write GPIO
#  byte 1: xxxx dcba     GPIO3-0 output values (1=high)
#  byte 2: xxxx dcba     GPIO3-0 data-direction register (1=output)
#  byte 3: xxxx xxxx     SPDIF
usb_ptt_on() {

    gpio=$1
    iomask=$((1 << (gpio - 1) ))
    iodata=$((1 << (gpio - 1) ))

    # echo options
    #    -n   do not output the trailing newline
    #    -e   enable interpretation of backslash escapes

#    exec 5<> /dev/hidraw2
#    echo -n -e \\x00\\x00\\x01\\x01\\x00 >&5

    # report number, HID output report, GPIO state, data direction
    echo -n -e \\x00\\x00\\x${iomask}\\x${iodata}\\x00 > /dev/$HID_FILE
#   echo -n -e \\x00\\x00\\x04\\x04\\x00 > /dev/hidraw2

#    exec 5>&-
}
usb_ptt_off() {
    gpio=$1
    iomask=$((1 << (gpio - 1) ))
    iodata=0
    # report number, HID output report, GPIO state, data direction
    echo -n -e \\x00\\x00\\x${iomask}\\x${iodata}\\x00 > /dev/$HID_FILE
#   echo -n -e \\x00\\x00\\x04\\x00\\x00 > /dev/hidraw2
}

# ===== main

usb_hid_dev

usb_ptt_on 3
sleep 2
usb_ptt_off 3