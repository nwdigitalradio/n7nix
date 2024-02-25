#!/bin/bash
#
# Build debian packages for libax25, ax25apps, ax25tools
scriptname="`basename $0`"
user="pi"
maintainer="gunn@beeble"

#SRC_DIR="/usr/local/src/ax25/linuxax25-master"
SRC_DIR="/usr/local/src/linuxax25"
PKGDIR="/home/$user/n7nix/ax25/debpkg/"

# ===== main

# Be sure we are running as root
if (( `id -u` != 0 )); then
   echo "$scriptname: Sorry, must be root.  Exiting...";
   exit 1;
fi

prog_name="checkinstall"
type -P $prog_name  >/dev/null 2>&1
if [ "$?"  -ne 0 ]; then
    # checkinstall not installed
    apt-get install -y -q $prog_name
fi

# Check for existing libraries
existingLibs="libax25.la libax25.so.1.0.1 libax25.a libax25io.so.1.0.0 libax25io.la libax25io.a"
for libname in $existingLibs ; do
    full_lib_name="/usr/local/lib/$libname"
    echo "Deleting library: $full_lib_name"
    rm "$full_lib_name"
done

PROGRAM_LIST="ax25apps ax25tools libax25"
for prog_name in $PROGRAM_LIST ; do
    vernum=$(grep -i AC_INIT $SRC_DIR/$prog_name/configure.ac)
    vernum=$(echo "$vernum" | cut -f2 -d' '|cut -f1 -d',')
    echo "Updating $prog_name to version: $vernum"
done

pkgname="libax25"
pkgver="1.2.2"
SUFFIX="$pkgver-1_armhf.deb"
PKGLONGNAME="$pkgname"_"$SUFFIX"

echo
echo " ===== Make $pkgname Debian package"
echo
pushd $SRC_DIR/$pkgname

echo
echo " == Make clean"
echo
make clean

# summary: ax25 library for hamradio applications

checkinstall -D --nodoc \
--pkglicense=GPL2 \
--requires="" \
--maintainer="$maintainer" \
--pkgname=$pkgname \
--pkgversion="$pkgver"\
--pakdir=$PKGDIR \
make install

popd

if [ -e $PKGDIR?$PKGLONGNAME ] ; then
   echo "Found wierd name: $PKGDIR?$PKGLONGNAME - renaming"
   mv $PKGDIR?$PKGLONGNAME $PKGDIR$PKGLONGNAME
fi

# Summary: AX.25 ham radio applications

pkgname="ax25apps"
pkgver="2.1.0"
SUFFIX="$pkgver-1_armhf.deb"
PKGLONGNAME="$pkgname"_"$SUFFIX"

echo
echo " ===== Make $pkgname Debian package"
echo
pushd $SRC_DIR/$pkgname

echo
echo " == Make clean"
echo
make clean
rm etc/*.dist
#rm /usr/local/etc/ax25/*.conf.dist

# Summary: AX.25 ham radio applications

checkinstall -D --nodoc \
--pkglicense=GPL2 \
--requires="libax25 \(\>= 1.0.0\)" \
--maintainer="$maintainer" \
--pkgname=$pkgname \
--pkgversion="$pkgver" \
--pakdir=$PKGDIR \
make install installconf

popd

if [ -e $PKGDIR?$PKGLONGNAME ] ; then
   echo "Found wierd name: $PKGDIR?$PKGLONGNAME - renaming"
   mv $PKGDIR?$PKGLONGNAME $PKGDIR$PKGLONGNAME
fi

# Summary:  tools for AX.25 interface configurqation

pkgname="ax25tools"
pkgver="1.1.0"
SUFFIX="$pkgver-1_armhf.deb"
PKGLONGNAME="$pkgname"_"$SUFFIX"

echo
echo " ===== Make $pkgname Debian package"
echo
pushd $SRC_DIR/$pkgname

echo
echo " == Make clean"
echo
make clean
rm etc/*.conf
rm /usr/local/etc/ax25/*.conf.dist


# Summary:  tools for AX.25 interface configuration

checkinstall -D --nodoc \
--pkglicense=GPL2 \
--requires="libax25 \(\>= 1.0.0\)" \
--maintainer="$maintainer" \
--pkgname=$pkgname \
--pkgversion="$pkgver" \
--pakdir=$PKGDIR \
make install installconf

popd

if [ -e $PKGDIR?$PKGLONGNAME ] ; then
   echo "Found wierd name: $PKGDIR?$PKGLONGNAME - renaming"
   mv $PKGDIR?$PKGLONGNAME $PKGDIR$PKGLONGNAME
fi
