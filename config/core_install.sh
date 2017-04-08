#!/bin/bash
#
# Run this after copying a fresh compass file system image
#
# Uncomment this statement for debug echos
DEBUG=1

UPDATE_NOW=false
SERIAL_CONSOLE=true
myname="`basename $0`"

# trap ctrl-c and call function ctrl_c()
trap ctrl_c INT

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed")
}

# ===== function ctrl_c trap handler

function ctrl_c() {
        echo "Exiting script from trapped CTRL-C"
	exit
}

# ===== install direwolf from source

function install_direwolf_source() {
   num_cores=$(nproc --all)
   echo "=== Install direwolf from source using $num_cores cores"
   SRC_DIR="/usr/local/src/"
   cd "$SRC_DIR"
   git clone https://www.github.com/wb2osz/direwolf
   cd direwolf
   make -j$num_cores
   make install
   make install-conf
   # The following failed
   #  make install-rpi
   echo "copying direwolf config file from source to /etc/direwolf.conf"
   cp /root/direwolf.conf /etc
   # Build from source puts executable in /usr/local/bin
   # Copy executable here to not have to edit sysd/direwolf.service file
   cp /usr/local/bin/direwolf /usr/bin
}

# ===== main

echo "Initial core install/config script"

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

# Check if build tools have been installed.
echo " === Check build tools"
pkg_name="build-essential"
is_pkg_installed $pkg_name
if [ $? -eq 0 ] ; then
   echo "$myname: Will Install $pkg_name package"
   apt-get install -y -q mg jed rsync build-essential autoconf automake libtool git libasound2-dev whois libncurses5-dev
fi

if [ ! -d /lib/modules/$(uname -r)/ ] ; then
   echo "Modules directory /lib/modules/$(uname -r)/ does NOT exist"
   echo "Probably need to reboot, type: "
   echo "shutdown -r now"
   echo "and log back in"
   exit 1
fi

echo " === Verify not using default password"
# is there even a user pi?
ls /home | grep pi > /dev/null 2>&1
if [ $? -eq 0 ] ; then
   echo "User pi found"
   echo "Determine if default password is being used"

   # get salt
   SALT=$(grep -i pi /etc/shadow | awk -F\$ '{print $3}')

   PASSGEN=$(mkpasswd --method=sha-512 --salt=$SALT raspberry)
   PASSFILE=$(grep -i pi /etc/shadow | cut -d ':' -f2)

#   dbgecho "SALT: $SALT"
#   dbgecho "pass file: $PASSFILE"
#   dbgecho "pass  gen: $PASSGEN"

   if [ "$PASSFILE" = "$PASSGEN" ] ; then
      echo "User pi is using default password"
      echo "Need to change your password for user pi NOW"
      read -t 1 -n 10000 discard
      passwd pi
      if [ $? -ne 0 ] ; then
         echo "Failed to set password, exiting"
	 exit 1
      fi
   else
      echo "User pi not using default password."
   fi

else
   echo "User pi NOT found"
fi

# Check hostname
echo " === Verify hostname"
HOSTNAME=$(cat /etc/hostname | tail -1)
dbgecho "Current hostname: $HOSTNAME"

if [ "$HOSTNAME" = "raspberrypi" ] || [ "$HOSTNAME" = "compass" ] ; then
   # Change hostname
   echo "Using default host name: $HOSTNAME, change it"
   echo "Enter new host name followed by [enter]:"
   read -t 1 -n 10000 discard
   read -e HOSTNAME
   echo "$HOSTNAME" > /etc/hostname
fi


# Get hostname again incase it was changed
HOSTNAME=$(cat /etc/hostname | tail -1)

# Be sure system host name can be resolved

grep "127.0.1.1" /etc/hosts
if [ $? -eq 0 ] ; then
   # Found 127.0.1.1 entry
   # Be sure hostnames match
   HOSTNAME_CHECK=$(grep "127.0.1.1" /etc/hosts | awk {'print $2'})
   if [ "$HOSTNAME" != "$HOSTNAME_CHECK" ] ; then
      echo "Make host names match between /etc/hostname & /etc/hosts"
      sed -i -e "/127.0.1.1/ s/127.0.1.1\t.*/127.0.1.1\t$HOSTNAME/" /etc/hosts
   else
      echo "host names match between /etc/hostname & /etc/hosts"
   fi
else
   # Add a 127.0.1.1 entry to /etc/hosts
   sed -i '1i\'"127.0.1.1\t$HOSTNAME $HOSTNAME.localnet" /etc/hosts
   if [ $? -ne 0 ] ; then
      echo "Failed to modify /etchosts file"
   fi
fi

DATETZ=$(date +%Z)
dbgecho "Time zone: $DATETZ"

if [ "$DATETZ" == "UTC" ] ; then
   echo " === Set time zone"
   echo " ie. select America, then scroll down to 'Los Angeles'"
   echo " then hit tab & return ... wait for it"
   # pause to read above msg
   sleep 4
   dpkg-reconfigure tzdata
fi

echo " === Modify /boot/config.txt"

grep udrc /boot/config.txt > /dev/null 2>&1
if [ $? -ne 0 ] ; then
  # Add to bottom of file
  cat << EOT >> /boot/config.txt

# enable udrc
# dtoverlay=udrc
force_turbo=1

# Rotate lcd screen
lcd_rotate=2

#dtoverlay=udrc-boost-output
EOT
fi

# To enable serial console disable bluetooth
#  and change console to ttyAMA0
if [ "$SERIAL_CONSOLE" = "true" ] ; then
   cat << EOT >> /boot/config.txt
# Enable serial console
dtoverlay=pi3-disable-bt
EOT
   sed -i -e "/console/ s/console=serial0/console=ttyAMA0, 115200/" /boot/cmdline.txt
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

ln -s /usr/local/lib/libax25.so.1 /usr/lib/libax25.so.0

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
   # Get here if direwolf NOT installed, to install package
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
else
   echo "direwolf already installed"
fi

if [ ! -e /etc/direwolf.conf ] ; then
   echo "Direwolf: NO config file found!!"
   echo "$myname: direwolf install failed!"
   exit 1
else
   echo "direwolf: config file found OK"
fi

echo "=== Set alsa levels for UDRC"
# Does source directory for udrc alsa level setup script exist?
SRC_DIR="/usr/local/src/udrc"

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
./set-udrc-din6.sh  > /dev/null 2>&1

UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
echo "$(date "+%Y %m %d %T %Z"): core install script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "core install script FINISHED"
echo
cd $START_DIR
/bin/bash $START_DIR/app_install.sh core
exit 0
