#!/bin/bash
#
# Run this after copying a fresh compass file system image
#
# Uncomment this statement for debug echos
DEBUG=1

UPDDATE_NOW=false

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== main

# make sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root"
   exit 1
fi

" === Check for updates"
if [ "$UPDATE_NOW" = "true" ] ; then
  apt-get update
  apt-get upgrade
  apt-get install -y mg jed rsync build-essential autoconf automake libtool git libasound2-dev whois libncurses5-dev
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
      echo "Need to change your password for user pi NOW"
      exit 1
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
   echo "Using default hostname, change it"
   read HOSTNAME
   echo "$HOSTNAME" > /etc/hostname
fi


# Get hostname again incase it was changed
HOSTNAME=$(cat /etc/hostname | tail -1)

# Make sure system host name can be resolved

grep "127.0.1.1" /etc/hosts
if [ $? -eq 0 ] ; then
   # Found 127.0.1.1 entry
   # Make sure hostnames match
   HOSTNAME_CHECK=$(grep "127.0.1.1" /etc/hosts | awk {'print $2'})
   if [ "$HOSTNAME" != "$HOSTNAME_CHECK" ] ; then
      echo "host names do NOT match between /etc/hostname & /etc/hosts"
      exit 1
   fi
else
   # Add a 127.0.1.1 entry to /etc/hosts
   sed -i '1i\'"127.0.1.1\t$HOSTNAME $HOSTNAME.localnet" /etc/hosts
   if [ $? -ne 0 ] ; then
      echo "Failed to modify /etchosts file"
   fi
fi

echo " === Set time zone"
DATETZ=$(date +%Z)
dbgecho "TIme zone: $DATETZ"

if [ "$DATETZ" == "UTC" ] ; then
   dpkg-reconfigure tzdata
fi

echo " === Modify /boot/config.txt"
# Add to bottom of file
cat << EOT >> /boot/config

# enable udrc
dtoverlay=udrc
force_turbo=1

# Rotate lcd screen
lcd_rotate=2

#dtoverlay=udrc-boost-output
EOT

echo " === enable modules"
# Add to bottom of file
cat << EOT >> /etc/modules

i2c-dev
ax25
EOT

echo "enable ax25 module"
insmod /lib/modules/$(uname -r)/kernel/net/ax25/ax25.ko


echo " === Install libax25, ax25apps & ax25tools"

# Does source directory for ax25 utils exist?
SRC_DIR="/usr/local/src/ax25"

if [ ! -d $SRC_DIR ] ; then
   mkdir -p $SRC_DIR
   if [ $? -ne 0 ] ; then
      echo "Problems creating source directory: $SRC_DIR"
      exit 1
   fi
fi

cd $SRC_DIR

wget https://github.com/ve7fet/linuxax25/archive/master.zip
unzip master.zip
./updAX25.sh
# libraries are installed in /usr/local/lib
ldconfig
cd ax25tools
make installconf


echo "=== Install direwolf"
git clone https://www.github.com/wb2osz/direwolf
cd direwolf
make
make install
make install-conf
# This failed
make install-rpi

cp /root/direwolf.conf /etc

exit 0
