#!/bin/bash
#
# postfix_install.sh
#
# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
pkg_name="postfix"

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# ===== main

echo
echo "Postfix install START"

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root."
   exit 1
fi

# Test if postfix package has already been installed.
is_pkg_installed $pkg_name
if [ $? -ne 0 ] ; then
   echo "$scriptname: Will Install $pkg_name package"
   apt-get install -y -q $pkg_name
fi

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: postfix install script FINISHED" | tee -a $UDR_INSTALL_LOGFILE
echo
