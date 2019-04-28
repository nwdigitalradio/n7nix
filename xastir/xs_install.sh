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
BOOT_CFGFILE="/boot/config.txt"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

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

# ===== check onboard audio device enabled
function chk_onboard_audio() {

    # Is write turned on?
    b_fixit=$1

    # Is last line 'dtparam=audio=on' ?
    last_line=$(tail -n1 $BOOT_CFGFILE)
    audio_on_line="dtparam=audio=on"

    if [ "$last_line" != "$audio_on_line" ] ; then
        echo "  Last line in $BOOT_CFGFILE NOT: $audio_on_line"

        # Check if update is enabled
        if $b_fixit ; then
            # Add Comment character to beginning of current audio line
            sudo sed -i -e 's/^dtparam=audio=on/#&/' $BOOT_CFGFILE
            # Add audio enable line to bottom of file
            sudo tee -a $BOOT_CFGFILE << EOT

# Enable audio (loads snd_bcm2835)
dtparam=audio=on
EOT
        fi
    else
        echo "  Last line in $BOOT_CFGFILE OK"
    fi
}

#
# ===== main
#

# Do not run as root
if [[ $EUID -eq 0 ]]; then
    echo "*** DO NOT run as root ***" 2>&1
    exit 1
fi

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
    sudo apt-get -qy remove $progname
fi

# Install files required for build
echo
echo "Install Xastir build requirements"
# geotiff requires libproj
sudo apt-get -y -qq install libmotif-common libmotif-dev
sudo apt-get -y -qq install git autoconf automake xorg-dev graphicsmagick gv libmotif-dev libcurl4-openssl-dev
sudo apt-get -y -qq install gpsman gpsmanshp libpcre3-dev libproj-dev libdb5.3-dev python-dev libwebp-dev
# Do not install festival packages
# apt-get install shapelib libshp-dev festival festival-dev libgeotiff-dev libwebp-dev libgraphicsmagick1-dev
sudo apt-get -y -qq install shapelib libshp-dev libgeotiff-dev libwebp-dev libgraphicsmagick1-dev
sudo apt-get -y -qq install xfonts-100dpi xfonts-75dpi

# Build latest version from source
cd $SRC_DIR
if [ ! -d $SRC_DIR/Xastir ] ; then
    # get latest Xastir source
    # Will this over write existing source file
    git clone https://github.com/Xastir/Xastir.git
fi

echo
echo "Running bootstrap script"
cd Xastir
./bootstrap.sh
mkdir -p build
cd build
echo
echo "Running configure script"
../configure --without-festival CPPFLAGS="-I/usr/include/geotiff"
echo
echo "Running make with $(nproc) threads"
make -j$(nproc)
echo
echo "Running install"
sudo make install
sudo strip $ROOT_DST/bin/xastir

# create local xastir sound repo off of local home dir
cd
if [ ! -d /home/$USER/xastir-sounds/ ] ; then
    echo "Getting Xastir sound files."
    git clone https://github.com/Xastir/xastir-sounds
fi

# Enable desktop icon for xastir
cp /home/$USER/n7nix/xastir/xastir.desktop /home/$USER/Desktop

# If the local share dir does NOT exist use defaut share directory.
SHARE_DIR="$ROOT_DST/share/xastir"
XASTIR_CFG_FILE="/home/$USER/.xastir/config/xastir.cnf"

if [ ! -d "$SHARE_DIR" ] ; then
    echo "WARNING: expected directory: $SHARE_DIR"
    SHARE_DIR="/usr/share/xastir"
else
    # Change all configuration entries from /usr/share/xastir to /usr/local/share/xastir
    echo "Existing /usr/share/xastir directories in xastir.cnf"
    find /home/$USER/.xastir -type f -print | xargs grep -i "/usr/share/xastir"

    sed -i -e 's|/usr/share/xastir|/usr/local/share/xastir|g' $XASTIR_CFG_FILE

    echo "Changed /usr/share/xastir directories to /usr/local/share/xastir in xastir.cnf"
    find /home/$USER/.xastir -type f -print | xargs grep -i "/usr/local/share/xastir"
fi

# Copy silence.wav to xastir sound dir
sudo cp /home/$USER/n7nix/xastir/*.wav $SHARE_DIR/sounds
# Copy xastir audio alert sound files to xastir sound dir
sudo cp /home/$USER/xastir-sounds/sounds/*.wav $SHARE_DIR/sounds

# Change sound command in config file
# replace string after ':' in SOUND_COMMAND:play
silence_file="$SHARE_DIR/sounds/silence.wav"

sed -i -e "s|^SOUND_COMMAND:.*|SOUND_COMMAND:aplay -D \"plughw:0,1\" $silence_file |" $XASTIR_CFG_FILE

# Enable RPi on-board audio
# Rather than just deleting comment character need to put on last line

chk_onboard_audio true

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: Xastir install script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
echo
