#!/bin/bash
#
# Build debian packages for libax25, ax25apps, ax25tools


scriptname="`basename $0`"
SRC_DIR="/usr/local/src/linuxax25"
NIX_DIR="$HOME/n7nix/ax25/debpkg"

ax25apps_ver=2.0.1
ax25tools_ver=1.0.5
libax25_ver=1.1.3

PROGRAM_LIST="ax25apps ax25tools libax25"
for prog_name in $PROGRAM_LIST ; do
    if [ -e "$SRC_DIR"/$prog_name ] ; then
        vernum=$(grep -i AC_INIT $SRC_DIR/$prog_name/configure.ac)
        vernum=$(echo "$vernum" | cut -f2 -d' '|cut -f1 -d',')
        declare ${prog_name}_ver="$vernum"
        echo "Found source for $prog_name, version: $vernum"
    else
        progver="${prog_name}_ver"
        echo "File: $SRC_DIR/$prog_name does NOT exist, using $SRC_DIR/${prog_name}_${progver}-1"
    fi
done

echo "ax25apps_ver=$ax25apps_ver"
echo "ax25tools_ver=$ax25tools_ver"
echo "libax25_ver=$libax25_ver"

cd $SRC_DIR
# Change name of diretory
if [ ! -d "ax25apps_${ax25apps_ver}-1" ] ; then
    mv ax25apps "ax25apps_${ax25apps_ver}-1"
fi
if [ ! -d "ax25tools_${ax25tools_ver}-1" ] ; then
    mv ax25tools "ax25tools_${ax25tools_ver}-1"
fi
if [ ! -d "libax25_${libax25_ver}-1" ] ; then
    mv libax25 "libax25_${libax25_ver}-1"
fi

# build the package
if [ -d "libax25_${libax25_ver}-1" ] ; then
    if [ ! -d "$SRC_DIR/libax25_${libax25_ver}-1/DEBIAN" ] ; then
        mkdir -p "$SRC_DIR/libax25_${libax25_ver}-1/DEBIAN"
    fi
    cp $NIX_DIR/libax25/control "libax25_${libax25_ver}-1/DEBIAN/control"
    sudo dpkg-deb --build libax25_${libax25_ver}-1
fi
if [ -d "ax25apps_${ax25apps_ver}-1" ] ; then
    if [ ! -d "$SRC_DIR/ax25apps_${ax25apps_ver}-1/DEBIAN" ] ; then
        mkdir -p "$SRC_DIR/ax25apps_${ax25apps_ver}-1/DEBIAN"
    fi
    cp $NIX_DIR/ax25apps/control "ax25apps_${ax25apps_ver}-1/DEBIAN/control"
    sudo dpkg-deb --build ax25apps_${ax25apps_ver}-1

fi
if [ -d "ax25tools_${ax25tools_ver}-1" ] ; then
    if [ ! -d "$SRC_DIR/ax25tools_${ax25tools_ver}-1/DEBIAN" ] ; then
        mkdir -p "$SRC_DIR/ax25tools_${ax25tools_ver}-1/DEBIAN"
    fi
    cp $NIX_DIR/ax25tools/control "ax25tools_${libax25_ver}-1/DEBIAN/control"
    sudo dpkg-deb --build ax25tools_${ax25tools_ver}-1
fi

ls $SRC_DIR

if [ 1 -eq 0 ] ; then
dpkg-deb --build libax25_1.1.3-1
dpkg-deb --build ax25apps_2.0.1-1
dpkg-deb --build ax25tools_1.0.5-1

fi
