#!/bin/bash
#
# mutt_install.sh
#
# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"
pkg_name="mutt"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# ===== main

echo
echo "mutt install START"

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root."
   exit 1
fi

# Test if mutt package has already been installed.
is_pkg_installed $pkg_name
if [ $? -ne 0 ] ; then
   echo "$scriptname: Will Install $pkg_name package"
   apt-get install -y -q $pkg_name
fi

echo "$(date "+%Y %m %d %T %Z"): mutt install script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "mutt install FINISHED"
echo