#!/bin/bash
#
# Uncomment this statement for debug echos
# DEBUG=1

scriptname="`basename $0`"
user=$(whoami)
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

SRC_DIR="/usr/local/src/"
DEB_DIR="/home/$user/debian"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function get_user

function get_user() {
   # Check if there is only a single user on this system
   if (( `ls /home | wc -l` == 1 )) ; then
      USER=$(ls /home)
   else
      echo "Enter user name ($(echo $USERLIST | tr '\n' ' ')), followed by [enter]:"
      read -e USER
   fi
}

# ==== function check_user
# verify user name is legit

function check_user() {
   userok=false
   dbgecho "$scriptname: Verify user name: $USER"
   for username in $USERLIST ; do
      if [ "$USER" = "$username" ] ; then
         userok=true;
      fi
   done

   if [ "$userok" = "false" ] ; then
      echo "User name ($USER) does not exist,  must be one of: $USERLIST"
      exit 1
   fi

   dbgecho "using USER: $USER"
}

# ===== main

echo -e "\n\tInstall HF programs\n"

# Check for any arguments
if (( $# != 0 )) ; then
   USER="$1"
fi

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

# Check if user name was supplied on command line
if [ -z "$USER" ] ; then
    # prompt for call sign & user name
    # Check if there is only a single user on this system
    get_user
fi
# Verify user name
check_user


# Install js8call
js8call_rootver="0.10.1"
js8call_ver="$js8call_rootver"-devel
wget https://s3.amazonawsCD.com/js8call/${js8call_rootver}/js8call_${js8call_ver}_armhf.deb

wsjtx_ver="1.9.1"

echo "install wsjt-x ver: $wsjtx_ver"
# wsjt-x home page:
#  - https://physics.princeton.edu/pulsar/k1jt/wsjtx.html
wget http://physics.princeton.edu/pulsar/K1JT/wsjtx_1.9.1_armhf.deb

hamlib_ver="3.3"

echo "install hamlib ver: $hamlib_ver"
sudo apt-get remove libhamlib2

cd "$SRC_DIR"
HAMLIB_SRC_DIR=$SRC_DIR/hamlib-$hamlib_ver

wget https://sourceforge.net/projects/hamlib/files/hamlib/$hamlib_ver/hamlib-$hamlib_ver.tar.gz
tar -zxvf hamlib-$hamlib_ver.tar.gz
sudo chown -R $USER:$USER $HAMLIB_SRC_DIR
cd hamlib-$hamlib_ver
./configure --prefix=/usr/local --enable-static
make
sudo make install
sudo ldconfig

fldigi_ver="4.0.18"

echo "Install fldigi ver: $fldigi_ver"

cd "$SRC_DIR"
FLDIGI_SRC_DIR=$SRC_DIR/fldigi-$fldigi_ver

# instructions from here: http://www.kk5jy.net/fldigi-build/
sudo apt-get install libfltk1.3-dev libjpeg9-dev libxft-dev libxinerama-dev libxcursor-dev libsndfile1-dev libsamplerate0-dev portaudio19-dev libusb-1.0-0-dev libpulse-dev
wget http://www.w1hkj.com/files/fldigi/fldigi-$fldigi_ver.tar.gz
#wget -N https://sourceforge.net/projects/fldigi/files/fldigi/fldigi-$FLDIGICUR.tar.gz

tar -zxvsf fldigi-$fldigi_ver.tar.gz
sudo chown -R $USER:$USER $FLDIGI_SRC_DIR
cd fldigi-$fldigi_ver
./configure
make
sudo make install
sudo ldconfig
cd ..

flrig_ver="1.3.41"

echo "install flrig ver: $flrig_ver"

cd "$SRC_DIR"
FLRIG_SRC_DIR=$SRC_DIR/flrig-$flrig_ver

wget http://www.w1hkj.com/files/flrig/flrig-$flrig_ver.tar.gz
tar -zxvf flrig-$flrig_ver.tar.gz
sudo chown -R $USER:$USER $FLRIG_SRC_DIR
cd flrig-$flrig_ver
./configure --prefix=/usr/local --enable-static
make
sudo make install

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: HF programs install script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
echo
