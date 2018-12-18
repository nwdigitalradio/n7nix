#!/bin/bash

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
PKGLIST="iptables iptables-persistent"

USER=
BIN_FILES="iptable-check.sh iptable-flush.sh iptable-up.sh"

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

#
# ===== main
#

echo "setup iptables"

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

# if there are any args on command line assume it's
# user name & callsign
if (( $# != 0 )) ; then
   USER="$1"
else
   get_user
fi

if [ -z "$USER" ] ; then
   echo "USER string is null, get_user"
   get_user
else
   echo "USER=$USER not null"
fi

check_user
BIN_DIR="/home/$USER/bin"

for filename in `echo ${BIN_FILES}` ; do
   cp $filename $BIN_DIR
done

# check if packages are installed
dbgecho "Check packages: $PKGLIST"

# Note: This should be in core_install.sh
#
# These rules block Bonjour/Multicast DNS (mDNS) addresses from iTunes
# or Avahi daemon.  Avahi is ZeroConf/Bonjour compatible and installed
# by default.
#
# Setup iptables then install iptables-persistent or manually update
# rules.v4

# Fix for iptables-persistent broken
#  https://discourse.osmc.tv/t/failed-to-start-load-kernel-modules/3163/14
#  https://www.raspberrypi.org/forums/viewtopic.php?f=63&t=174648

filename="/etc/modules-load.d/cups-filters.conf"
if [ -e "$filename" ] ; then
    sed -i -e 's/^#*/#/' $filename
fi

for pkg_name in `echo ${PKGLIST}` ; do

   is_pkg_installed $pkg_name
   if [ $? -ne 0 ] ; then
      echo "$scriptname: Will Install $pkg_name program"
      apt-get -qy install $pkg_name
   fi
done

# use iptables-persistent
CREATE_IPTABLES=false
IPTABLES_FILES="/etc/iptables/rules.ipv4.ax25 /lib/dhcpcd/dhcpcd-hooks/70-ipv4.ax25"
for ipt_file in `echo ${IPTABLES_FILES}` ; do

   if [ -f $ipt_file ] ; then
      echo "iptables file: $ipt_file exists"
   else
      echo "Need to create iptables file: $ipt_file"
      CREATE_IPTABLES=true
   fi
done

if [ "$CREATE_IPTABLES" = "true" ] ; then

    # Setup some iptable rules
    echo
    echo "== setup iptables"
    sudo $BIN_DIR/iptable-up.sh

    sh -c "iptables-save > /etc/iptables/rules.ipv4.ax25"

    cat  > /lib/dhcpcd/dhcpcd-hooks/70-ipv4.ax25 <<EOF
iptables-restore < /etc/iptables/rules.ipv4.ax25
EOF

fi

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: iptables install/config script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
echo
