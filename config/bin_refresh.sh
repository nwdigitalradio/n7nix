#!/bin/bash
#
# Copy scripts to local bin directory
# Used to update the DRAWS image
#
# Uncomment this statement for debug echos
# DEBUG=1

scriptname="`basename $0`"

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

# ===== function CopyAX25Files

function CopyAX25Files() {

# Check if directory exists.
if [ ! -d "$ax25bindir" ] ; then
   echo "ERROR: AX25 directory: $ax25bindir does NOT exist."
   exit 1
fi

sudo cp -u /home/$USER/n7nix/systemd/ax25/ax25-* $ax25bindir
sudo cp -u /home/$USER/n7nix/systemd/ax25/ax25dev-* $ax25bindir
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

cp -u /home/$USER/n7nix/systemd/bin/* $userbindir
cp -u /home/$USER/n7nix/bin/* $userbindir
cp -u /home/$USER/n7nix/debug/ax25-reset.sh $userbindir
cp -u /home/$USER/n7nix/iptables/iptable-*.sh $userbindir
cp -u /usr/local/src/paclink-unix/test_scripts/chk_perm.sh $userbindir
cp -u /home/$USER/n7nix/hostap/ap-*.sh $userbindir
cp -u /home/$USER/n7nix/config/bin_refresh.sh $userbindir

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

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

get_user
check_user

CopyDesktopFiles
userbindir="/home/$USER/bin"
CopyBinFiles
cd $userbindir

ax25bindir="/usr/local/etc/ax25"
CopyAX25Files

