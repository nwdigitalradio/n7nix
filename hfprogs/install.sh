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

echo -e "\n\t$(tput setaf 4) Install HF programs$(tput setaf 7)\n"

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


js8call_rootver="0.12.0"
js8call_ver="$js8call_rootver"-devel
PKG_REQUIRE_JS8CALL="libqgsttools-p1 libqt5multimedia5 libqt5multimedia5-plugins libqt5multimediaquick-p5 libqt5multimediawidgets5 libqt5qml5 libqt5quick5 libqt5serialport5"
echo "Install js8call ver: $js8call_ver"
download_filename="js8call_${js8call_ver}_armhf.deb"

if [ ! -e "$SRC_DIR/$download_filename" ] ; then
    cd "$SRC_DIR"
    sudo wget https://s3.amazonaws.com/js8call/${js8call_rootver}/$download_filename
    if [ $? -ne 0 ] ; then
        echo "$(tput setaf 1)FAILED to download file: $download_filename$(tput setaf 7)"
    else
        sudo apt-get install -y "$PKG_REQUIRE_JS8CALL"
        sudo dpkg -i $download_filename
    fi
fi

#wsjtx_ver="1.9.1"
wsjtx_ver="2.0.0"

echo "install wsjt-x ver: $wsjtx_ver"
download_filename="wsjtx_${wsjtx_ver}_armhf.deb"
cd "$SRC_DIR"
# wsjt-x home page:
#  - https://physics.princeton.edu/pulsar/k1jt/wsjtx.html
sudo wget http://physics.princeton.edu/pulsar/K1JT/$download_filename
if [ $? -ne 0 ] ; then
    echo "$(tput setaf 1)FAILED to download file: $download_filename$(tput setaf 7)"
else
    sudo dpkg -i $download_filename
fi

hamlib_ver="3.3"
echo "install hamlib ver: $hamlib_ver"
sudo apt-get remove libhamlib2

download_filename="hamlib-${hamlib_ver}.tar.gz"
HAMLIB_SRC_DIR=$SRC_DIR/hamlib-$hamlib_ver

# hamlib takes a long time to build,
#  check if there is a previous installation

if [ ! -d "$HAMLIB_SRC_DIR/tests" ] ; then
    cd "$SRC_DIR"

    sudo wget https://sourceforge.net/projects/hamlib/files/hamlib/$hamlib_ver/$download_filename
    if [ $? -ne 0 ] ; then
        echo "$(tput setaf 1)FAILED to download file: $download_filename$(tput setaf 7)"
    else
        sudo tar -zxvf $download_filename
        if [ $? -ne 0 ] ; then
            echo "$(tput setaf 1)FAILED to untar file: $download_filename $(tput setaf 7)"
        else
            sudo chown -R $USER:$USER $HAMLIB_SRC_DIR
            cd hamlib-$hamlib_ver
            ./configure --prefix=/usr/local --enable-static
            echo -e "\n$(tput setaf 4)Starting hamlib build(tput setaf 7)\n"
            make
            echo -e "\n$(tput setaf 4)Starting hamlib install(tput setaf 7)\n"
            sudo make install
            sudo ldconfig
        fi
    fi
else
    echo -e "\n\t$(tput setaf 4)Using previously built hamlib-$hamlib_ver$(tput setaf 7)\n"
    echo
fi

fldigi_ver="4.0.18"

echo "Install fldigi ver: $fldigi_ver"

FLDIGI_SRC_DIR=$SRC_DIR/fldigi-$fldigi_ver
download_filename="fldigi-$fldigi_ver.tar.gz"

# fldigi takes a long time to build,
#  check if there is a previous installation

if [ ! -d "$FLDIGI_SRC_DIR" ] ; then
    # instructions from here: http://www.kk5jy.net/fldigi-build/
    PKG_REQUIRE_FLDIGI="libfltk1.3-dev libjpeg9-dev libxft-dev libxinerama-dev libxcursor-dev libsndfile1-dev libsamplerate0-dev portaudio19-dev libusb-1.0-0-dev libpulse-dev"
    sudo apt-get install -y $PKG_REQUIRE_FLDIGI
    # wget -N  https://sourceforge.net/projects/fldigi/files/fldigi/fldigi-$FLDIGICUR.tar.gz

    cd "$SRC_DIR"
    sudo wget http://www.w1hkj.com/files/fldigi/$download_filename
    if [ $? -ne 0 ] ; then
        echo "$(tput setaf 1)FAILED to download file: $download_filename$(tput setaf 7)"
    else
        sudo tar -zxvsf $download_filename
        sudo chown -R $USER:$USER $FLDIGI_SRC_DIR
        cd fldigi-$fldigi_ver
        ./configure
        echo -e "\n$(tput setaf 4)Starting fldigi build(tput setaf 7)\n"
        make
        echo -e "\n$(tput setaf 4)Starting fldigi install(tput setaf 7)\n"
        sudo make install
        sudo ldconfig
    fi
fi

flrig_ver="1.3.41"

echo "install flrig ver: $flrig_ver"

FLRIG_SRC_DIR=$SRC_DIR/flrig-$flrig_ver
download_filename="flrig-$flrig_ver.tar.gz"

if [ ! -d "$FLRIG_SRC_DIR" ] ; then
    cd "$SRC_DIR"
    sudo wget http://www.w1hkj.com/files/flrig/$download_filename
    if [ $? -ne 0 ] ; then
        echo "$(tput setaf 1)FAILED to download file: $download_filename$(tput setaf 7)"
    else
        sudo tar -zxvf $download_filename
        sudo chown -R $USER:$USER $FLRIG_SRC_DIR
        cd flrig-$flrig_ver
        ./configure --prefix=/usr/local --enable-static
        make
        sudo make install
    fi
fi

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: HF programs install script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
echo
