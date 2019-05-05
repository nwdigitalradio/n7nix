#!/bin/bash
#
# Run this script after:
#  - core_install.sh or
#  - first boot from an SD card image created with image_install.sh
#
# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
CFG_FINISHED_MSG="core config script FINISHED"

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

cp -u /home/$USER/n7nix/systemd/bin/* $userbindir
cp -u /home/$USER/n7nix/bin/* $userbindir
cp -u /home/$USER/n7nix/iptables/iptable-*.sh $userbindir
cp -u /usr/local/src/paclink-unix/test_scripts/chk_perm.sh $userbindir
cp -u /home/$USER/n7nix/hostap/ap-*.sh  $userbindir

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

    if [ ! -z "$ip_addr" ] ; then

        count_dots=$(grep -o "\." <<< "$ip_addr" | wc -l)
        if (( count_dots != 3 )) ; then
            dbgecho "Error: Wrong number of dots in ipaddr: $ip_addr $count_dots"
            return 1
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
    else
        # Return code for no ip address inputted.
        retcode=0
    fi
    return $retcode
}

# ===== function is_hostname
# Has hostname already been changed?

function is_hostname() {
    retcode=0
    # Check hostname
    HOSTNAME=$(cat /etc/hostname | tail -1)

    # Check for any of the default hostnames
    if [ "$HOSTNAME" = "raspberrypi" ] || [ "$HOSTNAME" = "compass" ] || [ "$HOSTNAME" = "draws" ] || [ -z "$HOSTNAME" ] ; then
        retcode=1
    fi
#    dbgecho "is_hostname ret: $retcode"
    ret_hostname=$retcode
    return $retcode
}

# ===== function is_password
# Has password already been changed?

function is_password() {

    retcode=0
    GREPCMD="grep -i"

    if [ ! -r /etc/shadow ] ; then
        if [ ! -z "$DEBUG" ] ; then
            echo -e "\n\t$(tput setaf 1)Do NOT have permission to read passwd file $(tput setaf 7)\n"
        fi
        GREPCMD="sudo grep -i"
    fi

    # get salt
    SALT=$(sudo grep -i pi /etc/shadow | awk -F\$ '{print $3}')

    PASSGEN_RASPBERRY=$(mkpasswd --method=sha-512 --salt=$SALT raspberry)
    PASSGEN_NWCOMPASS=$(mkpasswd --method=sha-512 --salt=$SALT nwcompass)
    PASSFILE=$($GREPCMD pi /etc/shadow | cut -d ':' -f2)

#   dbgecho "SALT: $SALT"
#   dbgecho "pass file: $PASSFILE"
#   dbgecho "pass  gen raspberry: $PASSGEN_RASPBERRY"
#   dbgecho "pass  gen nwcompass: $PASSGEN_NWCOMPASS"

    if [ "$PASSFILE" = "$PASSGEN_RASPBERRY" ] || [ "$PASSFILE" = "$PASSGEN_NWCOMPASS" ] ; then
        echo "User pi is using default password"
        retcode=1
    fi
#    dbgecho "is_password ret: $retcode"
    ret_password=$retcode
    return $retcode
}

# ===== function is_logappcfg
# Has there been a log file entry for app_config.sh core script?

function is_logappcfg() {
    retcode=1

    if [ -e "$UDR_INSTALL_LOGFILE" ] ; then
         grep -i "$CFG_FINISHED_MSG" "$UDR_INSTALL_LOGFILE" > /dev/null 2>&1
        retcode="$?"
    else
        echo "File: $UDR_INSTALL_LOGFILE does not exist"
    fi
#    dbgecho "is_logappcfg ret: $retcode"
    ret_logappcfg=$retcode
    return $retcode
}

# ===== function check locale settings
# Compare country code in X11 layout, WPA config file & iw reg settings

function check_locale() {
    wificonf_file="/etc/wpa_supplicant/wpa_supplicant.conf"
    x11_country=$(localectl status | grep "X11 Layout" | cut -d ':' -f2)
    # Remove preceeding white space
    x11_country="$(sed -e 's/^[[:space:]]*//' <<<"$x11_country")"
    # Convert to upper case
    x11_country=$(echo "$x11_country" | tr '[a-z]' '[A-Z]')

    iw_country=$(iw reg get | grep -i country | cut -d' ' -f2 | cut -d':' -f1)
    # Convert to upper case
    iw_country=$(echo "$iw_country" | tr '[a-z]' '[A-Z]')

    if [ -e "$wificonf_file" ] ; then
        wifi_country=$(grep -i "country=" "$wificonf_file" | cut -d '=' -f2)
        # Remove preceeding white space
        wifi_country="$(sed -e 's/^[[:space:]]*//' <<<"$wifi_country")"
        # Convert to upper case
        wifi_country=$(echo "$wifi_country" | tr '[a-z]' '[A-Z]')

    else
        echo "Local country code check: WiFi config file: $wificonf_file, does not exist"
        wifi_country="00"
    fi

    if [ "$x11_country" == "$wifi_country" ] && [ "$x11_country" == "$iw_country" ]; then
        echo "Locale country codes consistent among WiFi cfg file, iw reg & X11: $wifi_country"
    else
        echo "Locale country codes do not match: WiFi: $wifi_country, iw: $iw_country, X11: $x11_country."
     fi
}

# ===== main

runmsg="Initial"
if is_logappcfg ; then
    # How many times has this script been run?
    runcnt=$(grep -c "$CFG_FINISHED_MSG" "$UDR_INSTALL_LOGFILE")
    runmsg="  Already run $runcnt time(s): "
fi

echo "$runmsg core config script"

# Find path to scripts to be run
currentdir=$(pwd)
echo "current dir: $currentdir"
# Get path one level down
pathdn1=$( echo ${currentdir%/*})
dbgecho "Test pwd: $currentdir, path: $pathdn1"

# Determine if driver has enumerated device
aplay -l | grep -i udrc > /dev/null 2>&1
if [ "$?" -ne 0 ] ; then
    # There are a couple of things that might cause this problem.
    # Check if there is a conflict with AudioSense-Pi driver
    $pathdn1/bin/chk_conflict.sh
    # Check if on-board audio enable is in wrong location in /boot/config.txt file
    $pathdn1/bin/chk_bootcfg.sh
    echo "udrc driver load problem, must reboot !"
    exit 1
fi

# Check that dtoverlay name is correct for HAT detected.
# Needs to be either draws or udrc
$pathdn1/bin/chk_bootcfg.sh

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root"
   exit 1
fi

# Confirm that config core script has not been run yet.
cfg_script_name="app_config.sh core"
if is_hostname && is_password && is_logappcfg ; then
    echo "$cfg_script_name has already been run, exiting"
    echo "-- cfg_script_name  hostname: $ret_hostname, passwd: $ret_password, logfile: $ret_logappcfg"
    exit 1
fi

# echo "-- cfg_script_name  hostname: $ret_hostname, passwd: $ret_password, logfile: $ret_logappcfg"

START_DIR=$(pwd)

echo " === Verify not using default password"
# is there even a user pi?
ls /home | grep pi > /dev/null 2>&1
if [ $? -eq 0 ] ; then
   echo "User pi found"
   echo "Determine if default password is being used"

    if ! is_password ; then
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

hostname_default="draws"

# Check hostname

echo "=== Verify current hostname: $HOSTNAME"

# Check for any of the default hostnames
if ! is_hostname  ; then
   # Change hostname
   echo "Current host name: $HOSTNAME, change it"
   echo "Enter new host name followed by [enter]:"
   read -t 1 -n 10000 discard
   read -e HOSTNAME

   if [ ! -z "$HOSTNAME" ] ; then
       echo "Setting new hostname: $HOSTNAME"
   else
       echo "Setting hostname to default: $hostname_default"
       HOSTNAME="$hostname_default"
   fi
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

if [ "$DATETZ" == "UTC" ] || [ "$DATETZ" == "GMT" ] || [ "$DATETZ" == "BST" ] ; then
   echo " === Set time zone"
   echo " ie. select America, then scroll down to 'Los Angeles'"
   echo " then hit tab & return ... wait for it"
   # pause to read above msg
   sleep 4
   dpkg-reconfigure tzdata
fi

check_locale
echo "=== Set WiFi country code to $x11_country"

# Not sure if this works in countries other than US.
# Convert country code to lower case
country_code=$(echo "$x11_country" | tr '[A-Z]' '[a-z]')
# Set WiFi country code in first line of wpa_supplicant config file.
sed -i '1i\'"country=$country_code" /etc/wpa_supplicant/wpa_supplicant.conf
# Set WiFi regulatory domain
iw reg set $x11_country
check_locale

echo "=== Put some scripts in local bin dir"

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

echo "=== Set alsa levels for UDRC"

# Set alsa levels with script
# Sets left channel levels for Kenwood & right channel for Alinco
./setalsa-default.sh  > /dev/null 2>&1
retcode="$?"
dbgecho "Set sound card levels return: $retcode"

echo "=== Set ip addresses on AX.25 interfaces"
# Insert the two ip addresses into the ax25-upd script
ax25upd_filename="/etc/ax25/ax25-upd"

# If the IP addresses have already been changed then use the changed
# addresses as the default

# Reference:
#  https://www.febo.com/packet/linux-ax25/ax25-config.html
# Default addresses for reference
dummy_ipaddress_0="192.168.255.2"
dummy_ipaddress_1="192.168.255.3"

ipaddr_ax0=$(grep -i "IPADDR_AX0=" "$ax25upd_filename" | cut -d'=' -f2)
#Remove surronding quotes
ipaddr_ax0="${ipaddr_ax0%\"}"
ipaddr_ax0="${ipaddr_ax0#\"}"
cur_ipaddr_ax0="$ipaddr_ax0"

ipaddr_ax1=$(grep -i "IPADDR_AX1=" "$ax25upd_filename" | cut -d'=' -f2)
#Remove surronding quotes
ipaddr_ax1="${ipaddr_ax1%\"}"
ipaddr_ax1="${ipaddr_ax1#\"}"
cur_ipaddr_ax1="$ipaddr_ax1"

echo "Current AX.25 ip addresses: ax0: $ipaddr_ax0, ax1: $ipaddr_ax1"
echo "If you do not understand or care about the following just hit enter for default values"

while  ! get_ipaddr ax0 ; do
    echo "Input error, try again"
done
if [ ! -z "$ip_addr" ] ; then
    echo "Setting ax0 to $ip_addr"
    ipaddr_ax0="$ip_addr"
fi

while  ! get_ipaddr ax1 ; do
    echo "Input error, try again"
done
if [ ! -z "$ip_addr" ] ; then
    echo "Setting ax1 to $ip_addr"
    ipaddr_ax1="$ip_addr"
fi

# Are the current IP addresses same as input addresses?
# ie. no addresses were input
if [ "$ipaddr_ax0" = "$cur_ipaddr_ax0" ] && [ "$ipaddr_ax1" = "$cur_ipaddr_ax1" ] ; then
    echo "No change to AX.25 IP addresses"
else

    echo -e "\n\t$(tput setaf 4)before: $(tput setaf 7)\n"
    grep -i "IPADDR_AX.=" "$ax25upd_filename"

    # Replace everything after string IPADDR_AX0
    sed -i -e "/IPADDR_AX0/ s/^IPADDR_AX0=.*/IPADDR_AX0=\"$ipaddr_ax0\"/"  $ax25upd_filename
    if [ "$?" -ne 0 ] ; then
        echo -e "\n\t$(tput setaf 1)Failed to change ax0 ip address $(tput setaf 7)\n"
    fi

    # Replace everything after string IPADDR_AX1
    sed -i -e "/IPADDR_AX1/ s/^IPADDR_AX1=.*/IPADDR_AX1=\"$ipaddr_ax1\"/"  $ax25upd_filename
    if [ "$?" -ne 0 ] ; then
        echo -e "\n\t$(tput setaf 1)Failed to change ax1 ip address $(tput setaf 7)\n"
    fi
fi

echo -e "\n\t$(tput setaf 4)after: $(tput setaf 7)\n"
grep -i "IPADDR_AX.=" $ax25upd_filename

echo "=== FINISHED Setting up ip addresses for AX.25 interfaces"

cd $START_DIR

# Make sure gpsd has set time to something close to reasonable.
chronyc makestep



echo "$(date "+%Y %m %d %T %Z"): $scriptname: $CFG_FINISHED_MSG" | tee -a $UDR_INSTALL_LOGFILE
echo

