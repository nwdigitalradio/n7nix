#!/bin/bash
#
# Run this after copying a fresh compass file system image
#
# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

# do upgrade, update outside of script since it can take some time
UPDATE_NOW=false

# Edit the following list with your favorite text editor
#   and set NONESSENTIAL_PKG to true
NONESSENTIAL_PKG_LIST="mg jed whois"
# set this to true if you even want non essential packages installed
NONESSENTIAL_PKG=true

BUILDTOOLS_PKG_LIST="rsync build-essential autoconf dh-autoreconf automake libtool git libasound2-dev libncurses5-dev"
REMOVE_PKG_LIST="libax25 libax25-dev ax25-apps ax25-tools"

# If the following is set to true, bluetooth will be disabled
SERIAL_CONSOLE=false

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

# ===== function install direwolf from source

function install_direwolf_source() {
   num_cores=$(nproc --all)
   echo "=== Install direwolf version $VER from source using $num_cores cores"
   SRC_DIR="/usr/local/src/"
   cd "$SRC_DIR"
# This gets current HOT version
#   git clone https://www.github.com/wb2osz/direwolf
#   cd direwolf

   # This gets version $VER
   wget https://github.com/wb2osz/direwolf/archive/$VER.zip
   unzip $VER.zip
   cd direwolf-$VER

   make -j$num_cores
   make install
   make install-conf

   # This failed: make install-rpi

   echo "copying direwolf config file from source to /etc/direwolf.conf"
   cp /root/direwolf.conf /etc
   # Build from source puts executable in /usr/local/bin
   # Copy executable here to not have to edit sysd/direwolf.service file
   cp /usr/local/bin/direwolf /usr/bin
}

# ===== function install direwolf package

function install_direwolf_pkg() {
   echo "=== Install direwolf package"
   apt-get install -y -q direwolf
   if [ $? -ne 0 ] || [ ! -e /usr/share/doc/direwolf/examples/direwolf.conf* ]; then
      echo "Problem installing direwolf package"
      install_direwolf_source
   else
      echo "direwolf package successfully installed."
      echo "copying direwolf config file from package to /etc/direwolf.conf"
      cp /usr/share/doc/direwolf/examples/direwolf.conf* /etc
      gunzip /etc/direwolf.conf.gz
   fi
}

# ===== main

echo "Initial core install script"

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root"
   exit 1
fi

START_DIR=$(pwd)

if [ "$UPDATE_NOW" = "true" ] ; then
   echo " === Check for updates"
   apt-get update
   apt-get upgrade
fi

# NON essential package install section

if [ "$NONESSENTIAL_PKG" = "true" ] ; then
   # Check if non essential packages have been installed
   echo "=== Check for non essential packages"
   needs_pkg=false

   for pkg_name in `echo ${NONESSENTIAL_PKG_LIST}` ; do

      is_pkg_installed $pkg_name
      if [ $? -ne 0 ] ; then
         echo "$scriptname: Will Install $pkg_name program"
         needs_pkg=true
         break
      fi
   done

   if [ "$needs_pkg" = "true" ] ; then
      echo -e "Installing some non essential packages"

      apt-get install -y -q $NONESSENTIAL_PKG_LIST
      if [ "$?" -ne 0 ] ; then
         echo "Non essential packages install failed. Please try this command manually:"
         echo "apt-get install -y $NONESSENTIAL_PKG_LIIST"
      fi
   fi

   echo "Non essential packages installed."
fi

# build tools install section

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

if [ ! -d /lib/modules/$(uname -r)/ ] ; then
   echo "Modules directory /lib/modules/$(uname -r)/ does NOT exist"
   echo "Probably need to reboot, type: "
   echo "shutdown -r now"
   echo "and log back in"
   exit 1
fi

echo " === Modify /boot/config.txt"

grep "force_turbo" /boot/config.txt > /dev/null 2>&1
if [ $? -ne 0 ] ; then
  # Add to bottom of file
  cat << EOT >> /boot/config.txt

# enable udrc if no eeprom
# dtoverlay=udrc
force_turbo=1
EOT
fi

# To enable serial console disable bluetooth
#  and change console to ttyAMA0
if [ "$SERIAL_CONSOLE" = "true" ] ; then
   echo "=== Disabling Bluetooth & enabling serial console"
   cat << EOT >> /boot/config.txt
# Enable serial console
dtoverlay=pi3-disable-bt
EOT
   sed -i -e "/console/ s/console=serial0/console=ttyAMA0,115200/" /boot/cmdline.txt
fi

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

echo " === Install libax25, ax25apps & ax25tools"
# libax25, ax25apps & ax25tools are about to be installed from source
# - first check that any packages are installed and uninstall them
echo " Check for previous packages installed"

for pkg_name in `echo ${REMOVE_PKG_LIST}` ; do

   is_pkg_installed $pkg_name
   if [ $? -eq 0 ] ; then
      echo "$scriptname: Will remove $pkg_name"
      apt-get purge -y -q $pkg_name
      if [ "$?" -ne 0 ] ; then
         echo "Conflicting package removal failed. Please try this command manually:"
         echo "apt-get purge -y $pkg_name"
      fi
   fi
done

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
cd $AX25_SRCDIR/ax25apps
make installconf

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
echo " === libax25, ax25apps & ax25tools install FINISHED"

# Test if direwolf has previously been installed.
#  - if not installed try installing Debian package
#  - if package install fails try installing from github repo.

echo "Test if direwolf has been installed"
# type command will return 0 if program is installed
type -P direwolf &>/dev/null
if [ $? -ne 0 ] ; then
   install_direwolfs_source
else
   echo "direwolf already installed"
fi

# This will happen if something else has already installed direwolf
if [ ! -e /etc/direwolf.conf ] ; then
   echo "Direwolf: config file NOT installed!"
   echo "copying direwolf config file from package to /etc/direwolf.conf"
   cp /usr/share/doc/direwolf/examples/direwolf.conf* /etc
   gunzip /etc/direwolf.conf.gz
fi

if [ ! -e /etc/direwolf.conf ] ; then
   echo "$scriptname: direwolf install failed!"
   exit 1
else
   echo "direwolf: config file found OK"
fi

SRC_DIR="/usr/local/src/udrc"

# Does source directory for udrc alsa level setup script exist?
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
wget -O set-udrc-din6.sh -qt 3 https://goo.gl/7rXUFJ
if [ $? -ne 0 ] ; then
   echo "FAILED to download alsa level setup file."
   exit 1
fi
chmod +x set-udrc-din6.sh

echo "$(date "+%Y %m %d %T %Z"): core install script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "core install script FINISHED"
echo
cd $START_DIR
/bin/bash $START_DIR/app_install.sh core
