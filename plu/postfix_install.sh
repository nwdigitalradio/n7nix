#!/bin/bash
#
# postfix_install.sh <user_name>
#
# Uncomment this statement for debug echos
DEBUG=1

myname="`basename $0`"
pkg_name="postfix"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed")
}

# ===== main

# Test if postfix package has already been installed.
is_pkg_installed $pkg_name
if [ $? -eq 0 ] ; then
   echo "$myname: Will Install $pkg_name package"
   apt-get install -y -q $pkg_name
fi

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

# if there are any args on command line assume it's a user name
if (( $# != 0 )) ; then
   USER="$1"
else
   # Check if there is only a single user on this system
   if (( `ls /home | wc -l` == 1 )) ; then
      USER=$(ls /home)
   else
      echo "Enter user name ($(echo $USERLIST | tr '\n' ' ')), followed by [enter]:"
      read USER
   fi
fi

# verify user name is legit
userok=false

for username in $USERLIST ; do
   if [ "$USER" = "$username" ] ; then
      userok=true;
   fi
done

if [ "$userok" = "false" ] ; then
   echo "User name does not exist,  must be one of: $USERLIST"
   exit 1
fi

dbgecho "using USER: $USER"

# Check if postfix master file has been modified
grep "wl2k" /etc/postfix/master.cf
if [ $? -ne 0 ] ; then
   {
      echo "wl2k      unix  -       n       n       -       1      pipe"
      echo "  flags=XFRhu user=$USER argv=/usr/local/libexec/mail.wl2k -m"
   } >> /etc/postfix/master.cf
else
   dbgecho " /etc/postfix/master.cf already modified."
fi

# Check if postfix main file has been modified
grep "transport_maps" /etc/postfix/master.cf
if [ $? -ne 0 ] ; then
  cat << EOT >> /etc/postfix/main.cf
transport_maps = hash:/etc/postfix/transport
smtp_host_lookup = dns, native
EOT
fi

# Make a transport file
{
echo "localhost     :"
echo "$(hostname)     local:"
echo "$(hostname).localnet     local:"
echo "#"
echo "*         wl2k:localhost"
} > /etc/postfix/transport

# create transport database file
postmap /etc/postfix transport
systemctl restart postfix
systemctl status postfix

# create /etc/aliases
{
echo " See man 5 aliases for format"
echo "postmaster:  $USER"
echo "root:  $USER"
echo "nobody:  $USER"
} > /etc/aliases

echo "postfix config FINISHED"
