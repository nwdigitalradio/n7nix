#!/bin/bash
#
# Updates source files & builds:
#  libax25, ax25apps, ax25tools
#
# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"

BUILDTOOLS_PKG_LIST="checkinstall rsync build-essential autoconf dh-autoreconf automake libtool git libncurses5-dev libncursesw5-dev"

# trap ctrl-c and call function ctrl_c()
trap ctrl_c INT

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# ===== function ctrl_c trap handler

function ctrl_c() {
        echo "Exiting script from trapped CTRL-C"
	exit
}

# ===== function install build tools

function install_build_tools() {
echo " === Check build tools"
needs_pkg=false

for pkg_name in `echo ${BUILDTOOLS_PKG_LIST}` ; do

   is_pkg_installed $pkg_name
   if [ $? -ne 0 ] ; then
      echo "$scriptname: Will Install $pkg_name program"
      needs_pkg=true
      break
   fi
done

if [ "$needs_pkg" = "true" ] ; then
   echo -e "Installing some build tool packages"

   apt-get install -y -q $BUILDTOOLS_PKG_LIST
   if [ "$?" -ne 0 ] ; then
      echo "Build tools package install failed. Please try this command manually:"
      echo "apt-get install -y $BUILDTOOLS_PKG_LIIST"
      exit 1
   fi
fi

echo "Build Tools packages installed."
}

# ===== function setup ax25 config directories

function ax25_config_dirs() {

echo "Check ax25 config dir"

# check if /etc/ax25 exists as a directory or symbolic link
if [ ! -d "/etc/ax25" ] || [ ! -L "/etc/ax25" ] ; then
   if [ ! -d "/usr/local/etc/ax25" ] ; then
      echo "ax25 directory /usr/local/etc/ax25 DOES NOT exist, ax25 install failed"
      exit 1
   else
      # Detect if /etc/ax25 is already a symbolic link
      if [[ -L "/etc/ax25" ]] ; then
         echo "Symbolic link to /etc/ax25 ALREADY exists"
      else
         echo "Making symbolic link to /etc/ax25"
         ln -s /usr/local/etc/ax25 /etc/ax25
      fi
   fi
else
   echo " Found link or directory /etc/ax25"
fi

# check if /var/ax25 exists as a directory or symbolic link
if [ ! -d "/var/ax25" ] || [ ! -L "/var/ax25" ] ; then
   if [ ! -d "/usr/local/var/ax25" ] ; then
      echo "ax25 directory /usr/local/var/ax25 DOES NOT exist, ax25 install failed"
      exit 1
   else
      # Detect if /var/ax25 is already a symbolic link
      if [[ -L "/var/ax25" ]] ; then
         echo " Symbolic link to /var/ax25 ALREADY exists"
      else
         echo "Making symbolic link to /var/ax25"
         ln -s /usr/local/var/ax25 /var/ax25
      fi
   fi
else
   echo " Found link or directory /var/ax25"
fi
}

# ===== function setup ax25 lib

function ax25_lib() {

# Since libax25 was built from source
# need to add a symbolic link to the /usr/lib directory
filename=/usr/lib/libax25.so.0
if [[ -L "$filename" ]] ; then
   echo " Symbolic link to $filename ALREADY exists"
else
   echo "Making symbolic link to $filename"
   ln -s /usr/local/lib/libax25.so.1 /usr/lib/libax25.so.0
fi

# pkg installed libraries are installed in /usr/lib
# built libraries are installed in /usr/local/lib
ldconfig

}

# ===== main

install_build_tools

echo " === Install libax25, ax25apps & ax25tools"
# libax25, ax25apps & ax25tools are about to be installed from source


# - first check that any packages are installed and uninstall them
#echo " Check for previous packages installed"
#
#REMOVE_PKG_LIST="libax25 libax25-dev ax25-apps ax25-tools"
#
#for pkg_name in `echo ${REMOVE_PKG_LIST}` ; do
#   is_pkg_installed $pkg_name
#   if [ $? -eq 0 ] ; then
#      echo "$scriptname: Will remove $pkg_name"
#      apt-get purge -y -q $pkg_name
#      if [ "$?" -ne 0 ] ; then
#         echo "Conflicting package removal failed. Please try this command manually:"
#         echo "apt-get purge -y $pkg_name"
#      fi
#   fi
#done

echo "Begin building libax25, ax25apps & ax25tools "

# Does source directory for ax25 utils exist?
SRC_DIR="/usr/local/src/ax25"

if [ ! -d $SRC_DIR ] ; then
   mkdir -p $SRC_DIR
   if [ $? -ne 0 ] ; then
      echo "Problems creating source directory: $SRC_DIR"
      exit 1
   fi
else
   dbgecho "Source dir: $SRC_DIR already exists"
fi

cd $SRC_DIR
# There are 2 sources for the "unofficial" libax25/tools/apps
#  One is from the github source directory
#  The other is from the github archive directory
#  They produce different source directories

AX25_SRCDIR=$SRC_DIR/linuxax25-master
#AX25_SRCDIR=$SRC_DIR/linuxax25

if [ ! -d $AX25_SRCDIR/libax25 ] || [ ! -d $AX25_SRCDIR/ax25tools ] || [ ! -d $AX25_SRCDIR/ax25apps ] ; then

   dbgecho "Proceding to download AX.25 library, tools & apps"
   dbgecho "Check: $AX25_SRCDIR/libax25  $AX25_SRCDIR/ax25tools  $AX25_SRCDIR/ax25apps"
   echo "Getting AX.25 update script from github"
   wget https://github.com/ve7fet/linuxax25/archive/master.zip
   unzip -q master.zip
#   git clone https://www.github.com/ve7fet/linuxax25/
fi

if [ ! -e "$AX25_SRCDIR/updAX25.sh" ] ; then
   echo "Getting AX.25 update script failed, can NOT locate: $AX25_SRCDIR/updAX25.sh."
   exit 1
fi

# Test if script is executable
if [ ! -x "$AX25_SRCDIR/updAX25.sh" ] ; then
   echo "Making executable: $AX25_SRCDIR/updAX25.sh."
   chmod +x $AX25_SRCDIR/updAX25.sh
fi

# Finally run the AX.25 update script
cd $AX25_SRCDIR
./updAX25.sh

# libraries are installed in /usr/local/lib
ldconfig

cd $AX25_SRCDIR/ax25tools
make installconf
# description: AX.25 ham radio applications
# 10 - Requires: [ libax25 (>= 1.0.0) ]

cd $AX25_SRCDIR/ax25apps
make installconf

ax25_config_dirs
ax25_lib

echo " === enable modules"
grep ax25 /etc/modules > /dev/null 2>&1
if [ $? -ne 0 ] ; then

# Add to bottom of file
cat << EOT >> /etc/modules

i2c-dev
ax25
EOT
fi

lsmod | grep -i ax25 > /dev/null 2>&1
if [ $? -ne 0 ] ; then
   echo "enable ax25 module"
   insmod /lib/modules/$(uname -r)/kernel/net/ax25/ax25.ko
fi

echo " === libax25, ax25apps & ax25tools install FINISHED"

