#!/bin/bash
#
# Build debian packages for libax25, ax25apps, ax25tools


scriptname="`basename $0`"
SRC_DIR="/usr/local/src/linuxax25"
NIX_DIR="$HOME/n7nix/ax25/debpkg"
build_libax25=false
build_ax25apps=false
build_ax25tools=true

ax25apps_ver="2.1.0"
ax25tools_ver="1.1.0"
libax25_ver="1.2.2"
arch="armhf"

# ===== main

# Be sure we're NOT running as root
if [[ $EUID == 0 ]] ; then
   echo "Must NOT be root"
   exit 1
fi


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
appsdir="ax25apps"
toolsdir="ax25tools"
libdir="libax25"

cd $SRC_DIR

if [ 1 -eq 0 ] ; then
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
libdir=libax25_${libax25_ver}-1

fi

if $build_libax25 ; then
# ====== build libax25 package ======
cd $SRC_DIR
echo -n "Checking for directory: $libdir, "

if [ -d "$libdir" ] ; then
    echo "Found directory: $libdir"
    if [ ! -d "$SRC_DIR/$libdir/DEBIAN" ] ; then
        mkdir -p "$SRC_DIR/$libdir/DEBIAN"
    fi
#    cp $NIX_DIR/libax25/control "$libdir/DEBIAN/control"

    targdir="$SRC_DIR/$libdir/debian"
    if [ -d  "$targdir" ] ; then
        rm -r "$targdir"
    fi
#    sudo dpkg-deb --build libax25_${libax25_ver}-1
    cd "$libdir"

# checkinstall requres manual entery of:
#  0 Maintainer: Lee Woldanski <ve7fet@tparc.org>
#  4 Release: 1
# 10 Requires: libc6(>=2.7-1~)

#    sudo checkinstall -d 2 -D --install=no --pkggroup=libs --pkgarch=armhf --pkgversion="$libax25_ver" --maintainer="Lee Woldanski <ve7fet@tparc.org>"
#    sudo checkinstall -d 2 -D --install=no --pkggroup=libs --pkgarch=armhf --pkgversion="$libax25_ver" --maintainer="ve7fet@tparc.org"
    sudo checkinstall -D --install=no --pkgrelease="1" --pakdir="$SRC_DIR"
    dpkg-deb -I $SRC_DIR/libax25_${libax25_ver}-1_$arch.deb
else
    echo "NOT found."
fi
fi  # $build_libax25

if $build_ax25apps ; then
# ====== build ax25apps package ======
cd $SRC_DIR
echo -n "Checking for directory: $appsdir, "

if [ -d "$appsdir" ] ; then
    echo "Found directory: $appsdir"
    if [ ! -d "$SRC_DIR/$appsdir/DEBIAN" ] ; then
        mkdir -p "$SRC_DIR/$appsdir/DEBIAN"
    fi
#    cp $NIX_DIR/ax25apps/control "$appdir/DEBIAN/control"
    targdir="$SRC_DIR/$appsdir/debian"
    if [ -d  "$targdir" ] ; then
        rm -r "$targdir"
    fi

#    sudo dpkg-deb --build ax25apps_${ax25apps_ver}-1
    cd "$appsdir"
# checkinstall requres manual entery of:
#  0 Maintainer: Lee Woldanski <ve7fet@tparc.org>
#  4 Release: 1
#  6 Group: hamradio
# 10 Requires: libncursesw5-dev,libax25 (>= 1.0.0)

    sudo checkinstall -D --install=no --pkgrelease=1 --pkgversion="$ax25apps_ver" --pakdir="$SRC_DIR"
    dpkg-deb -I $SRC_DIR/ax25apps_${ax25apps_ver}-1_$arch.deb

else
    echo "NOT found."
fi
fi # $build_ax25apps

if $build_ax25tools ; then
# ====== build ax25tools package ======
cd $SRC_DIR
echo -n "Checking for directory: $toolsdir, "

if [ -d "$toolsdir" ] ; then
    if [ ! -d "$SRC_DIR/$toolsdir/DEBIAN" ] ; then
        mkdir -p "$SRC_DIR/$toolsdir/DEBIAN"
    fi
    cp $NIX_DIR/ax25tools/control "$toolsdir/DEBIAN/control"

    targdir="$SRC_DIR/$toolsdir/debian"
    if [ -d  "$targdir" ] ; then
        rm -r "$targdir"
    fi
    cd "$toolsdir"
#    sudo dpkg-deb --build ax25tools_${ax25tools_ver}-1
    sudo checkinstall -D --install=no --pkgrelease="1" --pakdir="$SRC_DIR"
    dpkg-deb -I $SRC_DIR/ax25tools_${ax25tools_ver}-1_$arch.deb

else
    echo "NOT found."
fi

fi # $build_ax25tools

#dpkg-deb -c $SRC_DIR/libax25_${libax25_ver}-1.deb

ls -al $SRC_DIR/*.deb
