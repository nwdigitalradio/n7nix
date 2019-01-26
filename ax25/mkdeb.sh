#!/bin/bash
#
# Build debian packages for libax25, ax25apps, ax25tools
user="gunn"
scriptname="`basename $0`"

SRC_DIR="/usr/local/src/ax25/linuxax25-master"
PKGDIR="/home/$user/n7nix/ax25/debpkg/"

pkgname="libax25"
SUFFIX="1.1.1-1_armhf.deb"
PKGLONGNAME="$pkgname"_"$SUFFIX"

# Be sure we are running as root
if (( `id -u` != 0 )); then
   echo "$scriptname: Sorry, must be root.  Exiting...";
   exit 1;
fi

echo
echo " ===== Make $pkgname Debian package"
echo
pushd $SRC_DIR/$pkgname

# summary: ax25 library for hamradio applications

checkinstall -D --nodoc \
--pkglicense=GPL2 \
--requires="" \
--maintainer="gunn@brox" \
--pkgname=$pkgname \
--pakdir=$PKGDIR \
make install

popd

if [ -e $PKGDIR?$PKGLONGNAME ] ; then
   echo "Found wierd name: $PKGDIR?$PKGLONGNAME - renaming"
   mv $PKGDIR?$PKGLONGNAME $PKGDIR$PKGLONGNAME
fi

# Summary: AX.25 ham radio applications

pkgname="ax25apps"
SUFFIX="2.0.0-1_armhf.deb"
PKGLONGNAME="$pkgname"_"$SUFFIX"

echo
echo " ===== Make $pkgname Debian package"
echo
pushd $SRC_DIR/$pkgname

# Summary: AX.25 ham radio applications

checkinstall -D --nodoc \
--pkglicense=GPL2 \
--requires="libax25 \(\>= 1.0.0\)" \
--maintainer="gunn@brox" \
--pkgname=$pkgname \
--pakdir=$PKGDIR \
make install installconf

popd

if [ -e $PKGDIR?$PKGLONGNAME ] ; then
   echo "Found wierd name: $PKGDIR?$PKGLONGNAME - renaming"
   mv $PKGDIR?$PKGLONGNAME $PKGDIR$PKGLONGNAME
fi

# Summary:  tools for AX.25 interface configurqation

pkgname="ax25tools"
SUFFIX="1.0.4-1_armhf.deb"
PKGLONGNAME="$pkgname"_"$SUFFIX"

echo
echo " ===== Make $pkgname Debian package"
echo
pushd $SRC_DIR/$pkgname

# Summary:  tools for AX.25 interface configuration

checkinstall -D --nodoc \
--pkglicense=GPL2 \
--requires="libax25 \(\>= 1.0.0\)" \
--maintainer="gunn@brox" \
--pkgname=$pkgname \
--pakdir=$PKGDIR \
make install installconf

popd

if [ -e $PKGDIR?$PKGLONGNAME ] ; then
   echo "Found wierd name: $PKGDIR?$PKGLONGNAME - renaming"
   mv $PKGDIR?$PKGLONGNAME $PKGDIR$PKGLONGNAME
fi
