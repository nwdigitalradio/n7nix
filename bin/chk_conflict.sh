#!/bin/bash
#
# Detect & fix driver conflict with udrc and AudioSense-Pi add-on soundcard
# for kernel raspberrypi:rpi-4.14.98 and newer
# https://github.com/raspberrypi/linux/pull/2793/commits/45b10f4c61ce0e7fda303ba435f2ad3b0a5747c0
#
# If conflicting driver found will move to a tmp directory.
#
# Uncomment this statement for debug echos
# DEBUG=1

scriptname="`basename $0`"
USER=

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

echo
echo "Fix udrc driver conflict for Kernel release: $(uname -r)"
echo

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"
dbgecho "userlist: $USERLIST"

get_user
check_user

tmpdir="/home/$USER/tmp"

#
# Check for conflicting ASoC driver for the AudioSense-Pi soundcard

driverdir="/lib/modules/$(uname -r)/kernel/sound/soc/codecs"
audiosense_i2c_drivername="snd-soc-tlv320aic32x4-i2c.ko"
audiosense_codec_drivername="snd-soc-tlv320aic32x4.ko"

# Create a temporary directory
if [ ! -d "$tmpdir" ] ; then
    mkdir -p "$tmpdir"
fi

# Check for AudioSense i2c driver
if [ -e  "$driverdir/$audiosense_i2c_drivername" ] ; then
    echo "=== chk1: $audiosense_i2c_drivername exists, removing"
    sudo mv $driverdir/$audiosense_i2c_drivername $tmpdir
fi

# Check for AudioSense codec driver
if [ -e  "$driverdir/$audiosense_codec_drivername" ] ; then
    echo "=== chk2: $audiosense_codec_drivername exists, removing"
    sudo mv $driverdir/$audiosense_codec_drivername $tmpdir
fi

echo "=== Loaded module check"
lsmod | egrep -e '(udrc|tlv320)'

echo
echo "=== Sound card check"
aplay -l | grep -i udrc > /dev/null 2>&1
if [ "$?" -ne 0 ] ; then
    echo "udrc driver not loaded."
else
    echo "OK"
fi

