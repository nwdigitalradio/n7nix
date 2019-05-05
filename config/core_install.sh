#!/bin/bash
#
# Run this after copying a fresh compass file system image
#
# Uncomment this statement for debug echos
#DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

#DIREWOLF SOURCE VERSION to build
#DW_VER="1.5"
DW_VER="direwolf-dev"

# do upgrade, update outside of script since it can take some time
UPDATE_NOW=false

# Edit the following list with your favorite text editor
#   and set NONESSENTIAL_PKG to true
NONESSENTIAL_PKG_LIST="mg jed whois"
# set this to true if you even want non essential packages installed
NONESSENTIAL_PKG=true

BUILDTOOLS_PKG_LIST="rsync build-essential autoconf dh-autoreconf automake libtool git libasound2-dev libncurses5-dev"

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

# ===== function install build tools

function install_build_tools() {
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
libname=/usr/lib/libax25.so.0
if [[ -L "$libname" ]] ; then
   echo " Symbolic link to $libname ALREADY exists"
else
   echo "Making symbolic link to $libname"
   ln -s /usr/local/lib/libax25.so.1 $libname
fi

# pkg installed libraries are installed in /usr/lib
# built libraries are installed in /usr/local/lib
ldconfig

}

# ===== function install direwolf from source

function install_direwolf_source() {
    num_cores=$(nproc --all)

    echo "=== Install direwolf version $DW_VER from source using $num_cores cores"

#   apt-get install gpsd
    apt-get install libgps-dev

   SRC_DIR="/usr/local/src/"
   cd "$SRC_DIR"

# This gets current HOT version
#   git clone https://www.github.com/wb2osz/direwolf
#   cd direwolf

   # This gets version $DW_VER
   wget https://github.com/wb2osz/direwolf/archive/$DW_VER.zip
   unzip $DW_VER.zip
   cd direwolf-$DW_VER

   make -j$num_cores
   make install
   make install-conf

   # This failed: make install-rpi

   echo "copying direwolf config file from source to /etc/direwolf.conf"
   cp /root/direwolf.conf /etc
   mv /root/direwolf.conf /root/direwolf.conf.dist
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

# ===== function get product id of HAT

function get_prod_id() {
# Initialize product ID
PROD_ID=
prgram="udrcver.sh"
which $prgram
if [ "$?" -eq 0 ] ; then
   dbgecho "Found $prgram in path"
   $prgram -
   PROD_ID=$?
else
   currentdir=$(pwd)
   # Get path one level down
   pathdn1=$( echo ${currentdir%/*})
   dbgecho "Test pwd: $currentdir, path: $pathdn1"
   if [ -e "$pathdn1/bin/$prgram" ] ; then
       dbgecho "Found $prgram here: $pathdn1/bin"
       $pathdn1/bin/$prgram -
       PROD_ID=$?
   else
       echo "Could not locate $prgram default product ID to draws"
       PROD_ID=4
   fi
fi
}

# ===== function modify /boot/config.txt

function mod_config_txt() {
echo " === Modify /boot/config.txt"

# default to draws HAT
set_dtoverly="dtoverlay=draws,alsaname=udrc"

grep "force_turbo" /boot/config.txt > /dev/null 2>&1
if [ $? -ne 0 ] ; then
    if [[ "$PROD_ID" -eq 4 ]] ; then
        set_dtoverlay="dtoverlay=draws,alsaname=udrc"
    else
        set_dtoverlay="dtoverlay=udrc"
    fi
    # Add to bottom of file
    cat << EOT >> /boot/config.txt

# enable udrc/draws if no eeprom
$set_dtoverlay
force_turbo=1
EOT
else
    echo -e "\n\t$(tput setaf 4)File: /boot/config.txt NOT modified: prod_id=$PROD_ID $(tput setaf 7)\n"
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
}

# ===== main

echo "Initial core install script"

get_prod_id
echo "HAT product id: $PROD_ID"

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root"
   exit 1
fi

START_DIR=$(pwd)

if [ "$UPDATE_NOW" = "true" ] ; then
   echo " === Check for updates"
   apt-get update
   apt-get upgrade -q -y
fi

install_build_tools

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

if [ ! -d /lib/modules/$(uname -r)/ ] ; then
   echo "Modules directory /lib/modules/$(uname -r)/ does NOT exist"
   echo "Probably need to reboot, type: "
   echo "shutdown -r now"
   echo "and log back in"
   exit 1
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

# Edit /boot/config.txt
mod_config_txt

# Add ax25 packages here
echo " === Install libax25, ax25apps & ax25tools"
cd $START_DIR
cd ..
echo "Installing from this directory $(pwd)"

dpkg -i ./ax25/debpkg/libax25_1.1.0-1_armhf.deb
dpkg -i ./ax25/debpkg/ax25apps_1.0.5-1_armhf.deb
dpkg -i ./ax25/debpkg/ax25tools_1.0.3-1_armhf.deb

ax25_config_dirs
ax25_lib

echo " === libax25, ax25apps & ax25tools install FINISHED"

cd $START_DIR

# gps required before direwolf build
pushd ../gps
echo "=== $scriptname: Install DRAWS gps programs"
./install.sh
popd > /dev/null

# Test if direwolf has previously been installed.
#  - if not installed try installing Debian package
#  - if package install fails try installing from github repo.

echo "Test if direwolf has been installed"
# type command will return 0 if program is installed
type -P direwolf &>/dev/null
if [ $? -ne 0 ] ; then
   install_direwolf_source
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

echo " === direwolf install FINISHED"

echo " === time sync before: $(date)"
program_name="chronyd"
type -P "$program_name"  &>/dev/null
if [ $? -eq 0 ] ; then
    echo "Daemon: ${program_name} found"
    sudo chronyc makestep
else
    echo -e "\n\t$(tput setaf 1)Chrony NOT installed $(tput setaf 7)\n"
fi
echo " === time sync after: $(date)"

echo "$(date "+%Y %m %d %T %Z"): $scriptname: core install script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "core install script FINISHED"
echo
cd $START_DIR
/bin/bash $START_DIR/app_install.sh core
