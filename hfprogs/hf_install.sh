#!/bin/bash
#
# Build & install the HF applications
#
# arguments:
#     none  - builds all HF applications
#     user  - builds all HF applications
#     user app version - builds a single HF application
#
# App names used in argument:
#  js8call, wsjtx, hamlib, fldigi, flrig, flmsg, flamp
#
# Uncomment this statement for debug echos
# DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

SRC_DIR="/usr/local/src/"
USER=

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== Display program help info

usage () {
	(
	echo "Usage: $scriptname user_name [hfprog_name][hfprog_version]"
        echo "    login user name"
        echo "    hfprog_name needs to be one of:"
        echo "      js8call wsjtx hamlib fldigi flrig flmsg flamp"
        echo "    hfprog_version needs to be a valid program version number"
        echo
	) 1>&2
	exit 1
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

# ===== function build_js8call

function build_js8call() {

js8call_rootver="$1"
js8call_ver="$js8call_rootver"
download_filename="js8call_${js8call_ver}_armhf.deb"

PKG_REQUIRE_JS8CALL="libqgsttools-p1 libqt5multimedia5 libqt5multimedia5-plugins libqt5multimediaquick-p5 libqt5multimediawidgets5 libqt5qml5 libqt5quick5 libqt5serialport5"
echo "Install js8call ver: $js8call_ver"
cd "$SRC_DIR"

if [ ! -e "$SRC_DIR/$download_filename" ] ; then
#    sudo wget https://s3.amazonaws.com/js8call/${js8call_rootver}/$download_filename
    sudo wget http://files.js8call.com/${js8call_rootver}/$download_filename
    if [ $? -ne 0 ] ; then
        echo "$(tput setaf 1)FAILED to download file: $download_filename $(tput setaf 7)"
        exit 1
    else
        sudo apt-get -qq install -y $PKG_REQUIRE_JS8CALL
        sudo dpkg -i $download_filename
    fi
else
    sudo apt-get -qq install -y $PKG_REQUIRE_JS8CALL
    sudo dpkg -i $download_filename
fi

}

# ===== function build_wsjtx

function build_wsjtx() {

wsjtx_ver="$1"
echo "install wsjt-x ver: $wsjtx_ver"
download_filename="wsjtx_${wsjtx_ver}_armhf.deb"
cd "$SRC_DIR"

# wsjt-x home page:
#  - https://physics.princeton.edu/pulsar/k1jt/wsjtx.html
sudo wget http://physics.princeton.edu/pulsar/K1JT/$download_filename
if [ $? -ne 0 ] ; then
    echo "$(tput setaf 1)FAILED to download file: $download_filename $(tput setaf 7)"
    exit 1
else
    sudo dpkg -i $download_filename
fi

}

# ===== function build_hamlib

function build_hamlib() {

hamlib_ver="$1"
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
        echo "$(tput setaf 1)FAILED to download file: $download_filename $(tput setaf 7)"
        exit 1
    else
        sudo tar -zxvf $download_filename
        if [ $? -ne 0 ] ; then
            echo "$(tput setaf 1)FAILED to untar file: $download_filename $(tput setaf 7)"
        else
            sudo chown -R $USER:$USER $HAMLIB_SRC_DIR
            cd hamlib-$hamlib_ver
            ./configure --prefix=/usr/local --enable-static
            echo -e "\n$(tput setaf 4)Starting hamlib build $(tput setaf 7)\n"
            make
            echo -e "\n$(tput setaf 4)Starting hamlib install $(tput setaf 7)\n"
            sudo make install
            sudo ldconfig
        fi
    fi
else
    echo -e "\n\t$(tput setaf 4)Using previously built hamlib-$hamlib_ver $(tput setaf 7)\n"
    echo
fi
}

# ===== function build_fldigi

function build_fldigi() {

fldigi_ver="$1"
echo "Install fldigi ver: $fldigi_ver"
download_filename="fldigi-$fldigi_ver.tar.gz"

FLDIGI_SRC_DIR=$SRC_DIR/fldigi-$fldigi_ver

# fldigi takes a long time to build,
#  check if there is a previous installation

PKG_REQUIRE_FLDIGI="libfltk1.3-dev libjpeg9-dev libxft-dev libxinerama-dev libxcursor-dev libsndfile1-dev libsamplerate0-dev portaudio19-dev libusb-1.0-0-dev libpulse-dev"
sudo apt-get install -y $PKG_REQUIRE_FLDIGI

if [ ! -d "$FLDIGI_SRC_DIR" ] ; then
    # instructions from here: http://www.kk5jy.net/fldigi-build/
    # wget -N  https://sourceforge.net/projects/fldigi/files/fldigi/fldigi-$FLDIGICUR.tar.gz
    cd "$SRC_DIR"

    sudo wget http://www.w1hkj.com/files/fldigi/$download_filename
    if [ $? -ne 0 ] ; then
        echo "$(tput setaf 1)FAILED to download file: $download_filename $(tput setaf 7)"
        exit 1
    else
        sudo apt-get build-dep fldigi
        sudo tar -zxvsf $download_filename
        sudo chown -R $USER:$USER $FLDIGI_SRC_DIR
        cd fldigi-$fldigi_ver

        ./configure --with-hamlib --with-flxmlrpc
        echo -e "\n$(tput setaf 4)Starting fldigi build $(tput setaf 7)\n"
        make
        echo -e "\n$(tput setaf 4)Starting fldigi install $(tput setaf 7)\n"
        sudo make install
        sudo ldconfig
    fi
fi
}

# ===== function build any of flxmlrpc flrig, flmsg, flamp

function build_flapp() {

flapp_ver="$1"
flapp="$2"

echo "install $flapp ver: $flapp_ver"

FLAPP_SRC_DIR=$SRC_DIR/$flapp-$flapp_ver
download_filename="$flapp-$flapp_ver.tar.gz"

if [ ! -d "$FLAPP_SRC_DIR" ] ; then
    cd "$SRC_DIR"
    sudo wget http://www.w1hkj.com/files/$flapp/$download_filename
    if [ $? -ne 0 ] ; then
        echo "$(tput setaf 1)FAILED to download file: $download_filename $(tput setaf 7)"
        exit 1
    else
        sudo tar -zxvf $download_filename
        sudo chown -R $USER:$USER $FLAPP_SRC_DIR
        cd $flapp-$flapp_ver
        ./configure --prefix=/usr/local --enable-static
        make
        sudo make install
        sudo ldconfig
    fi
fi
}


# ===== main

echo -e "\n\t$(tput setaf 4) Install HF programs $(tput setaf 7)\n"

# Check for any arguments
if (( $# != 0 )) ; then
    key="$1"
    case $key in
        -h)
            usage
            exit 1
        ;;

        *)
            echo "User specified: $key"
            USER="$1"
        ;;
    esac
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

# If there are no command line options build everything

if [[ $# -eq 1 ]] && [[ "$1" -eq "$USER" ]] ; then
    hfapp="ALL"

    build_js8call "1.0.0"
    build_wsjtx "2.0.1"
    build_hamlib "3.3"
    build_flapp "0.1.4" flxmlrpc
    build_flapp "1.3.43" flrig
    build_flapp "4.0.8" flmsg
    build_flapp "2.2.04" flamp
    build_fldigi "4.1.03"
else

    if [[ $# -ne 3 ]] ; then
        echo "Wrong number of arguments: $#"
        echo "Args: $@"
        usage
        exit 1
    fi
    hfapp="$2"
    case $hfapp in
        js8call)
            build_js8call "$3"
        ;;
        wsjtx)
            build_wsjtx "$3"
        ;;
        hamlib)
            build_hamlib "$3"
        ;;
        fldigi)
            build_fldigi "$3"
        ;;
        flrig)
            build_flapp "$3" "flrig"
        ;;
        flmsg)
            build_flapp "$3" "flmsg"
        ;;
        flamp)
            build_flapp "$3" "flamp"
        ;;
        flxmlrpc)
            build_flapp "$3" "flxmlrpc"
        ;;
        *)
            echo "Undefined argument $hfapp"
            usage
            exit 1
        ;;
    esac
fi

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: HF program ($hfapp) install script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
echo
