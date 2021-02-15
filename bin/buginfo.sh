#!/bin/bash
#
# Display information to debug DRAWS codec not enumerated
#
# Problem first found with kernel:
#  5.10.11-v7l+ #1399 SMP Thu Jan 28 12:09:48 GMT 2021
# on Feb. 13, 2021


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

# ===== main

echo "== Kernel version:"
uname -a

echo
echo "== Codec driver check:"
dmesg | grep -i "tlv320a"

echo
echo "== DRAWS driver check:"
check_udrc

echo
echo "== Pi Version"
piver.sh

echo
echo "== /boot/config"
grep -v "^$\|^#" /boot/config.txt
