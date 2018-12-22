#!/bin/bash
#
# Run this script after core_install.sh
#

# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# trap ctrl-c and call function ctrl_c()
trap ctrl_c INT

# ===== function ctrl_c trap handler

function ctrl_c() {
        echo "Exiting script from trapped CTRL-C"
	exit
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

# ===== function CopyBinFiles

function CopyBinFiles() {

# Check if directory exists.
if [ ! -d "$userbindir" ] ; then
   mkdir $userbindir
fi

cp /home/$USER/n7nix/systemd/bin/* $userbindir
cp /home/$USER/n7nix/bin/* $userbindir
chown -R $USER:$USER $userbindir

echo
echo "FINISHED copying bin files"
}

# ===== function valid_ip

# Copied from here:
# http://www.linuxjournal.com/content/validating-ip-address-bash-script
#
# Test an IP address for validity:
# Usage:
#      valid_ip IP_ADDRESS
#      if [[ $? -eq 0 ]]; then echo good; else echo bad; fi
#   OR
#      if valid_ip IP_ADDRESS; then echo good; else echo bad; fi
#
function valid_ip() {
    local  ip=$1
    local  stat=1

    dbgecho "Verifying ip address: $ip"

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    dbgecho "Verifying ip address ret: $stat"
    return $stat
}

# ===== function get_ipaddr

function get_ipaddr() {

    ax25_intface=$1
    retcode=1
    ip_addr=
    # clear the read buffer
    read -t 1 -n 10000 discard

    echo -n "Enter ip address for AX.25 interface $ax25_intface followed by [enter]"

    # -p display PROMPT without a trailing new line
    # -e readline is used to obtain the line
    read -ep ": " ip_addr

    count_dots=$(grep -o "\." <<< "$ip_addr" | wc -l)
    if (( count_dots != 3 )) ; then
        dbgecho "Error: Wrong number of dots in ipaddr: $ip_addr $count_dots"
        if [ -z "$ip_addr" ] ; then
            dbgecho "ip address is NULL"
            return 0
        else
            return 1
        fi
    fi
    valid_ip $ip_addr
    retcode=$?
    if [ $retcode -eq 1 ] ; then
        echo "INVALID IP address: $ip_addr"
        retcode=1
    else
        echo "Valid ip address: $ip_addr"
        retcode=0
    fi

return $retcode
}

# ===== main

echo "Initial core config script"

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root"
   exit 1
fi

START_DIR=$(pwd)

echo " === Verify not using default password"
# is there even a user pi?
ls /home | grep pi > /dev/null 2>&1
if [ $? -eq 0 ] ; then
   echo "User pi found"
   echo "Determine if default password is being used"

   if [ ! -r /etc/shadow ] ; then
       echo -e "\n\t$(tput setaf 1)Do NOT have permission to read passwd file, exiting $(tput setaf 7)\n"
       exit
   fi

   # get salt
   SALT=$(grep -i pi /etc/shadow | awk -F\$ '{print $3}')

   PASSGEN_RASPBERRY=$(mkpasswd --method=sha-512 --salt=$SALT raspberry)
   PASSGEN_NWCOMPASS=$(mkpasswd --method=sha-512 --salt=$SALT nwcompass)
   PASSFILE=$(grep -i pi /etc/shadow | cut -d ':' -f2)

#   dbgecho "SALT: $SALT"
#   dbgecho "pass file: $PASSFILE"
#   dbgecho "pass  gen raspberry: $PASSGEN_RASPBERRY"
#   dbgecho "pass  gen nwcompass: $PASSGEN_NWCOMPASS"

   if [ "$PASSFILE" = "$PASSGEN_RASPBERRY" ] || [ "$PASSFILE" = "$PASSGEN_NWCOMPASS" ] ; then
      echo "User pi is using default password"
      echo "Need to change your password for user pi NOW"
      read -t 1 -n 10000 discard
      passwd pi
      if [ $? -ne 0 ] ; then
         echo -e "\n\t$(tput setaf 1)Failed to set password, exiting $(tput setaf 7)\n"
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
dbgecho "$scriptname: Current hostname: $HOSTNAME"

# Check for any of the default hostnames
if [ "$HOSTNAME" = "raspberrypi" ] || [ "$HOSTNAME" = "compass" ] || [ "$HOSTNAME" = "draws" ] ; then
   # Change hostname
   echo "Using default host name: $HOSTNAME, change it"
   echo "Enter new host name followed by [enter]:"
   read -t 1 -n 10000 discard
   read -e HOSTNAME
   echo "$HOSTNAME" > /etc/hostname
fi

# Get hostname again incase it was changed
HOSTNAME=$(cat /etc/hostname | tail -1)

echo "=== Set mail hostname"
echo "$HOSTNAME.localhost" > /etc/mailname

# Be sure system host name can be resolved

grep "127.0.1.1" /etc/hosts
if [ $? -eq 0 ] ; then
   # Found 127.0.1.1 entry
   # Be sure hostnames match
   HOSTNAME_CHECK=$(grep "127.0.1.1" /etc/hosts | awk {'print $2'})
   if [ "$HOSTNAME" != "$HOSTNAME_CHECK" ] ; then
      echo "Make host names match between /etc/hostname & /etc/hosts"
      sed -i -e "/127.0.1.1/ s/127.0.1.1\t.*/127.0.1.1\t$HOSTNAME ${HOSTNAME}.localnet/" /etc/hosts
   else
      echo "host names match between /etc/hostname & /etc/hosts"
   fi
else
   # Add a 127.0.1.1 entry to /etc/hosts
   sed -i '1i\'"127.0.1.1\t$HOSTNAME $HOSTNAME.localnet" /etc/hosts
   if [ $? -ne 0 ] ; then
      echo "Failed to modify /etc/hosts file"
   fi
fi

echo "=== Set time zone & current time"

DATETZ=$(date +%Z)
dbgecho "Time zone: $DATETZ"

if [ "$DATETZ" == "UTC" ] || [ "$DATETZ" == "GMT" ] ; then
   echo " === Set time zone"
   echo " ie. select America, then scroll down to 'Los Angeles'"
   echo " then hit tab & return ... wait for it"
   # pause to read above msg
   sleep 4
   dpkg-reconfigure tzdata
fi

echo "=== Set alsa levels for UDRC"

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

get_user
check_user

userbindir=/home/$USER/bin
CopyBinFiles
cd $userbindir

# Adjust clock
# source ./set-time.sh

# Set alsa levels with script
# Sets left channel levels for Kenwood & right channel for Alinco
./setalsa-default.sh  > /dev/null 2>&1
retcode="$?"
dbgecho "Set sound card levels return: $retcode"

echo "=== Set ip addresses on AX.25 interfaces"

# Reference:
#  https://www.febo.com/packet/linux-ax25/ax25-config.html
dummy_ipaddress_0="192.168.255.2"
dummy_ipaddress_1="192.168.255.3"

ipaddr_ax0="$dummy_ipaddress_0"
ipaddr_ax1="$dummy_ipaddress_1"

echo "If you do not understand or care about the following just hit enter for default values"

while  ! get_ipaddr ax0 ; do
    echo "Input error, try again"
done
if [ ! -z "$ip_addr" ] ; then
    echo "Setting ax0 to $ip_addr"
    ipaddr_ax0="$ip_addr"
else
    echo "ax0 using default: $ipaddr_ax0"
fi

while  ! get_ipaddr ax1 ; do
    echo "Input error, try again"
done
if [ ! -z "$ip_addr" ] ; then
    echo "Setting ax1 to $ip_addr"
    ipaddr_ax1="$ip_addr"
else
    echo "ax1 using default: $ipaddr_ax1"
fi

echo "AX.25 ip addresses: ax0: $ipaddr_ax0, ax1: $ipaddr_ax1"

# Insert the two ip addresses into the ax25-upd script

ax25upd_filename="/etc/ax25/ax25-upd"

echo -e "\n\t$(tput setaf 4)before: $(tput setaf 7)\n"
grep -i "IPADDR_AX.=" $ax25upd_filename

# Replace everything after strings IPADDR_AX0 & IPADDR_AX1
sed -i -e "/IPADDR_AX0/ s/^IPADDR_AX0=.*/IPADDR_AX0=\"$ipaddr_ax0\"/"  $ax25upd_filename
if [ "$?" -ne 0 ] ; then
    echo -e "\n\t$(tput setaf 1)Failed to change ax0 ip address $(tput setaf 7)\n"
fi

sed -i -e "/IPADDR_AX1/ s/^IPADDR_AX1=.*/IPADDR_AX1=\"$ipaddr_ax1\"/"  $ax25upd_filename
if [ "$?" -ne 0 ] ; then
    echo -e "\n\t$(tput setaf 1)Failed to change ax1 ip address $(tput setaf 7)\n"
fi

echo -e "\n\t$(tput setaf 4)after: $(tput setaf 7)\n"
grep -i "IPADDR_AX.=" $ax25upd_filename

echo "=== FINISHED Setting up ip addresses for AX.25 interfaces"

cd $START_DIR

echo "$(date "+%Y %m %d %T %Z"): $scriptname: core config script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "core config script FINISHED"
echo
