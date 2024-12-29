#!/bin/bash
#
# Copy scripts to local bin directory
# Used to update the DRAWS image
#
# Uncomment this statement for debug echos
# DEBUG=1

scriptname="`basename $0`"

mach_hardware=

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


# ==== function get_mach_hardware
# Set variable $suffix to either amd64, armhf or arm64

function get_mach_hardware() {
    # For RPi 32 bit
    # pat_0.15.0_linux_armhf.deb (Raspberry Pi 32-bit)
    #
    # For 64 bit Intel
    # pat_0.15.0_linux_amd64.deb

    # uname -m
    # x86_64
    # armv7l
    # aarch64

    mach_hardware="$(uname -m)"

    suffix=
    case $mach_hardware in

        "x86_64")
            suffix="amd64"
        ;;
        "armv7l")
            suffix="armhf"
        ;;
        "aarch64")
            suffix="arm64"
        ;;
        *)
            suffix="unknown"
            echo "Undefined machine hardware: $mach_hardware, exiting."
	    exit 1
        ;;
    esac

    echo "machine architecture: $mach_hardware, suffix: $suffix"
}



# ===== function CopyAX25Files

function CopyAX25Files() {

# Check if directory exists.
if [ ! -d "$ax25bindir" ] ; then
   echo "ERROR: AX25 directory: $ax25bindir does NOT exist."
   exit 1
fi

sudo cp -u /home/$USER/n7nix/ax25/ax25-showcfg.sh $userbindir
sudo cp -u /home/$USER/n7nix/ax25/ax25-setcfg.sh $userbindir

sudo cp -u /home/$USER/n7nix/ax25/port.conf $ax25bindir
sudo cp -u /home/$USER/n7nix/systemd/ax25/ax25-* $ax25bindir
sudo cp -u /home/$USER/n7nix/systemd/ax25/ax25dev-* $ax25bindir
sudo cp -u /home/$USER/n7nix/systemd/sysd/* /etc/systemd/system

sudo chown -R root:staff $ax25bindir

echo
echo "FINISHED copying AX.25 files"
}

# ===== function CopyBinFiles
# Copy files that should be in the local bin directory

function CopyBinFiles() {

# Check if directory exists.
if [ ! -d "$userbindir" ] ; then
   mkdir $userbindir
fi

# Copy miscellaneous scripts
cp -u /home/$USER/n7nix/systemd/bin/* $userbindir
cp -u /home/$USER/n7nix/bin/* $userbindir
cp -u /home/$USER/n7nix/iptables/iptable-*.sh $userbindir
cp -u /usr/local/src/paclink-unix/test_scripts/chk_perm.sh $userbindir

# Used to send generated messages in Winlink outbox
cp -u /home/$USER/n7nix/debug/wl2k_outboxchk.sh $userbindir
cp -u /home/$USER/n7nix/debug/wl2klog_sendmail.sh $userbindir

cp -u /home/$USER/n7nix/hostap/ap-*.sh $userbindir
cp -u /home/$USER/n7nix/hostap/fixed_ip.sh $userbindir

# Copy ardop & track file to local bin
cp -u /home/$USER/n7nix/ardop/ardop-* $userbindir
cp -u /home/$USER/n7nix/ardop/ardoplist.sh $userbindir
cp -u /home/$USER/n7nix/tracker/tracker-* $userbindir
cp -u /home/$USER/n7nix/tracker/updown_log.sh $userbindir
# include rigctl test script
cp -u /home/$USER/n7nix/ardop/qsy_test.sh $userbindir

# Copy baud rate chanage files to local bin
cp -u /home/$USER/n7nix/baudrate/speed_switch.sh $userbindir
cp -u /home/$USER/n7nix/baudrate/dw-ttcmd.sh $userbindir
cp -u /home/$USER/n7nix/baudrate/send-ttcmd.sh $userbindir

# Copy watchdog file
cp -u /home/$USER/n7nix/watchdog/wd-status.sh $userbindir

# Copy direwolf version display file
cp -u /home/$USER/n7nix/direwolf/dw_ver.sh $userbindir

# Copy scripts to support PAT AX.25/ARDOP
cp -u /home/$USER/n7nix/email/pat/listener_ctrl.sh $userbindir
cp -u /home/$USER/n7nix/email/pat/pat_ctrl.sh $userbindir
cp -u /home/$USER/n7nix/ardop/ardop_ctrl.sh $userbindir

# Update this script
cp -u /home/$USER/n7nix/config/bin_refresh.sh $userbindir
cp -u /home/$USER/n7nix/config/sensor_update.sh $userbindir

sudo chown -R $USER:$USER $userbindir

echo
echo "FINISHED copying bin files"
}

# ===== function CopyDesktopFiles

function CopyDesktopFiles() {


# Check if direwolf is running.
pid=$(pidof direwolf)
if [ $? -eq 0 ] ; then
    # Direwolf is running copy off icon
    cp -u /home/$USER/n7nix/ax25/icons/ax25-stop.desktop /home/$USER/Desktop/ax25-startstop.desktop
else
    cp -u /home/$USER/n7nix/ax25/icons/ax25-start.desktop /home/$USER/Desktop/ax25-startstop.desktop
fi
# Copy the desktop files to a common directory
cp -u /home/$USER/n7nix/ax25/icons/*.desktop /home/$USER/bin
# Copy both white back-ground & no back-ground icons
sudo cp -u /home/$USER/n7nix/ax25/icons/*.png /usr/share/pixmaps/
sudo cp -u /home/$USER/n7nix/ax25/icons/*.svg /usr/share/pixmaps/

echo
echo "FINISHED copying desktop files"
}

# ===== main

# Don't be root
if [[ $EUID == 0 ]] ; then
   echo "Do NOT run this script as root"
   exit 1
fi

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

get_user
check_user

# Set variable "mach_hardware"
get_mach_hardware

echo
echo "$(tput setaf 6) == Updating n7nix repo$(tput sgr0)"

cd
cd n7nix
git pull

echo
echo "$(tput setaf 6) == Updating local bin directory for user: $USER$(tput sgr0)"

CopyDesktopFiles
userbindir="/home/$USER/bin"
CopyBinFiles
cd $userbindir

ax25bindir="/usr/local/etc/ax25"
CopyAX25Files

# Only check sensors if running on an RPi
if [ "$mach_hardware" = "armv7l" ] || [ "$mach_hardware" = "aarch64" ] ; then
    # Check if DRAWS sensor config file needs updating
    program_name="/home/$USER/bin/sensor_update.sh"
    type -P "$program_name"  &>/dev/null
    if [ $? -eq 0 ] ; then
        echo "script: ${program_name} found"
        # Assumes not running as root
        sudo -u "$USER" $program_name
    else
        echo -e "\n\t$(tput setaf 1)Script: ${program_name} NOT installed for user: $(whoami) $(tput setaf 7)\n"
    fi
fi  # end machine hardware check
