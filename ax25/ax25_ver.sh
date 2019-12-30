#!/bin/bash
#
# Display debian source versions for libax25, ax25apps, ax25tools


scriptname="`basename $0`"
SRC_DIR="/usr/local/src/linuxax25"

PROGRAM_LIST="ax25apps ax25tools libax25"
for prog_name in $PROGRAM_LIST ; do
    if [ -e "$SRC_DIR"/$prog_name ] ; then
        vernum=$(grep -i AC_INIT $SRC_DIR/$prog_name/configure.ac)
        vernum=$(echo "$vernum" | cut -f2 -d' '|cut -f1 -d',')
        echo "Found source for $prog_name, version: $vernum"
    else
        echo "File: $SRC_DIR/$prog_name does NOT exist"
    fi
done
