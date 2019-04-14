#!/bin/bash
#
# Install APRS app xastir
#
# Uncomment this statement for debug echos
# DEBUG=1
USER=
ROOT_DST="/usr/local"
SRC_DIR="$ROOT_DST/src"

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

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

#
# ===== main
#
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

install_method="source"
is_pkg_installed $progname
if [ $? -ne 0 ] ; then
    echo "$scriptname: $progname will be installed/updated from source"
else
    # Found xastir package, will uninstall
    echo "$scriptname: Detected $progname package, will UNinstall."
    apt-get -qy remove $progname
fi

# Build latest version from source
cd $SRC_DIR
if [ ! -d $SRC_DIR/Xastir ] ; then
    # get latest Xastir source
    # Will this over write existing source file
    git clone https://github.com/Xastir/Xastir.git
fi

cd Xastir
./bootstrap.sh
mkdir -p build
cd build
../configure --without-festival CPPFLAGS="-I/usr/include/geotiff"
make -j$(nproc)
sudo make install
sudo strip $ROOT_DST/bin/xastir

# create local xastir sound repo off of local home dir
cd
git clone https://github.com/Xastir/xastir-sounds

# Enable desktop icon for xastir
cp /home/$USER/n7nix/xastir/xastir.desktop /home/$USER/Desktop

# If the local share dir does NOT exist use defaut share directory.
SHARE_DIR="$ROOT_DST/share/xastir"
if [ ! -d "$SHARE_DIR" ] ; then
    SHARE_DIR="/usr/share/xastir"
fi
# Copy silence.wav to xastir sound dir
sudo cp /home/$USER/n7nix/xastir/*.wav $SHARE_DIR/sounds
# Copy xastir audio alert sound files to xastir sound dir
sudo cp /home/$USER/xastir-sounds/*.wav $SHARE_DIR/sounds

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: Xastir install script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
echo
