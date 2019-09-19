#!/bin/bash
#
# Check swap size & enlarge if necessary

SWAPSIZE="1024"

# ===== function swap_size_check
# If swap too small, change config file /etc/dphys-swapfile & exit to
# do a reboot.
#
# To increase swap file size in /etc/dphys-swapfile:
# Default   CONF_SWAPSIZE=100    102396 KBytes
# Change to CONF_SWAPSIZE=1000  1023996 KBytes

function swap_size_check() {
    # Verify that swap size is large enough
    swap_size=$(swapon -s | tail -n1 | expand -t 1 | tr -s '[[:space:]] ' | cut -d' ' -f3)
    # Test if swap size is less than 1 Gig
    if (( swap_size < 1023996 )) ; then
        swap_config=$(grep -i conf_swapsize /etc/dphys-swapfile | cut -d"=" -f2)
        sudo sed -i -e "/CONF_SWAPSIZE/ s/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=$SWAPSIZE/" /etc/dphys-swapfile

        echo "Swap size too small for builds, changed from $swap_config to $SWAPSIZE ... need to reboot."
        exit 1
    fi
}

# ===== main

swap_size_check
