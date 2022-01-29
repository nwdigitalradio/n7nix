#!/bin/bash
#
# Display information to debug DRAWS codec not enumerated
#
# Problem first found with kernel:
#  5.10.11-v7l+ #1399 SMP Thu Jan 28 12:09:48 GMT 2021
# on Feb. 13, 2021
#
# Add display of:
#  - does DRAWS eeprom exist
#  - HAT version: assembly version, fab version
#  - RPi temperature

# Name of UDRC or DRAWS product version file
firmware_prod_verfile="/sys/firmware/devicetree/base/hat/product_ver"
firmware_prod_idfile="/sys/firmware/devicetree/base/hat/product_id"

# ===== function check udrc enumeration
function check_udrc() {
    CARDNO=$(aplay -l | grep -i udrc)

    if [ ! -z "$CARDNO" ] ; then
        echo "udrc card number line: $CARDNO"
        CARDNO=$(echo $CARDNO | cut -d ' ' -f2 | cut -d':' -f1)
        echo "udrc is sound card #$CARDNO"
    else
        echo " No udrc sound card found"
    fi
}

# ===== function display draws product id, assembly version, fab version
function draws_ver() {

    if [ -f $firmware_prod_verfile ] ; then

	# Read product id file
        UDRC_ID="$(tr -d '\0' < $firmware_prod_idfile)"

        # read product version
        product_ver=$(tr -d '\0' < $firmware_prod_verfile)
        assembly_rev=$(echo $product_ver | cut -f2 -d'x' | cut -c1-2)
        fab_rev=${product_ver: -2}

        # convert hex number to decimal
        assembly_rev=$(( 16#$assembly_rev ))
        fab_rev=$(( 16#$fab_rev ))

        printf "Product id: %s, ver: %s, Assembly rev: %d, fab rev: %d\n" $UDRC_ID $product_ver $assembly_rev $fab_rev
    else
        print "Firmware product version file does NOT exist"
    fi
}

# function check_hamlib
# Verify that there is only a single hamlib directory

function check_hamlib() {
    echo
    echo "== hamlib check"

    arm_hamlib_cnt=0
    local_hamlib_cnt=0

    # Check for older versions of hamlib
    hamlib_dir="/usr/lib/arm-linux-gnueabihf"
    if [ -d "$hamlib_dir" ] && [ -e $hamlib_dir/libhamlib.so.4 ] ; then
        libcnt=$(ls -1 $hamlib_dir/libhamlib* | wc -l)
        if ((libcnt > 0 )) ; then
            arm_hamlib_cnt=$libcnt
            echo "hamlib: Found $arm_hamlib_cnt hamlib files in $hamlib_dir"
            ls -alt $hamlib_dir/libhamlib*
	    echo
        else
            echo "hamlib: NO hamlib files found in $hamlib_dir"
        fi
    else
        echo "hamlib directory: $hamlib_dir files do NOT exist"
    fi

    # Check for newer versions of hamlib
    hamlib_dir="/usr/local/lib"
    if [ -d "$hamlib_dir" ] && [ -e "$hamlib_dir/libhamlib.so.4" ] ; then
        libcnt=$(ls -1 $hamlib_dir/libhamlib* | wc -l)
        if ((libcnt > 0 )) ; then
            local_hamlib_cnt=$libcnt
            echo "hamlib: Found $local_hamlib_cnt hamlib files in $hamlib_dir"
            ls -alt $hamlib_dir/libhamlib*
        else
            echo "hamlib: NO hamlib files found in $hamlib_dir"
        fi
    else
        echo "hamlib directory: $hamlib_dir files do NOT exist"
    fi

    echo
    hamlib_dir="/usr/lib/arm-linux-gnueabihf"
    if ((arm_hamlib_cnt > 0)) && ((local_hamlib_cnt > 0)) ; then
        echo "$(tput setaf 6)Need to remove conflicting hamlib files from: $hamlib_dir$(tput sgr0)"
    else
        echo "No conflicting hamlib files found"
    fi
}

# ===== main

echo "=== Versions ==="
echo "== Kernel:"
uname -a

echo
echo "== Firmware:"
vcgencmd version

echo
echo "== Pi hardware:"
piver.sh
vcgencmd measure_temp

echo
echo "== DRAWS hardware:"
draws_ver

echo
echo "== image version"
head -n 1 /var/log/udr_install.log

echo
echo "=== Checks ==="
echo "== Codec driver check:"
dmesg | grep -i "tlv320a"

echo
echo "== DRAWS driver check:"
check_udrc

echo
echo "== Boot 'fail' check:"
#dmesg | grep -i "sc16is7xx"
dmesg | grep -i "fail"

echo
echo "== GPS check:"
if [ -e /dev/ttySC0 ] && [ -e /dev/ttySC1 ] ; then
    echo "Serial devices OK"
else
    echo "One or more serial devices not found"
    ls /dev/ttySC*
fi
systemctl status gpsd | grep -i "error"
if [ $? -ne 0 ] ; then
    echo "gpsd OK"
fi

check_hamlib

echo
echo "== /boot/config file"
grep -v "^$\|^#" /boot/config.txt
