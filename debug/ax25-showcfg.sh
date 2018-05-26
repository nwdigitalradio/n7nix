#!/bin/bash

AX25_DEVICE_DIR="/proc/sys/net/ax25"
AX25_KISS_CFG="/etc/systemd/system/ax25dev.service"

echo " === kissparms ==="
grep -i "kissparms" $AX25_KISS_CFG
echo
echo " === ax.25 config ==="
for dir in $AX25_DEVICE_DIR/* ; do
    echo "Found directory: $dir"
    for file in $dir/* ; do
	fname="$(basename -- "$file")"
	echo -n "$fname: "
	cat $file
    done
    echo
done

