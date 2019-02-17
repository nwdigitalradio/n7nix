#!/bin/bash
#
# draws-manager install
#
# Uncomment this statement for debug echos
DEBUG=1

PROG="draws-manager"
scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
SRC_DIR="/usr/local/var"

INSTALL_PKG_REQUIRE="nodejs npm git"
SYSTEMD_DIR="/etc/systemd/system"
CFG_FILES="/etc/default/$PROG $SYSTEMD_DIR/$PROG.service"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {

    return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# ===== function files_exist()

function files_exist() {
   retcode=1

   for filename in `echo ${CFG_FILES}` ; do
      if [ ! -f "$filename" ] ; then
         retcode=0
      else
         echo "File check found: $filename"
      fi
   done
   return $retcode
}


# ===== main

echo "$(date "+%Y %m %d %T %Z"): $scriptname: $PROG install script START" | tee -a $UDR_INSTALL_LOGFILE

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "$scriptname: Must be root"
   exit 1
fi

# Check if there are any args on command line
if (( $# != 0 )) ; then
   echo "No args required."
fi

# check if required packages are installed
dbgecho "Check required packages: $INSTALL_PKG_REQUIRE"
needs_pkg=false

for pkg_name in `echo ${INSTALL_PKG_REQUIRE}` ; do

   is_pkg_installed $pkg_name
   if [ "$?" -ne 0 ] ; then
      echo "$scriptname: Will Install $pkg_name package"
      needs_pkg=true
      break
   fi
done

INITIAL_DIR=$(pwd)
cd "$SRC_DIR"

dbgecho "   Check for existence of local $PROG repo"

# Does repo directory exist?
if [ ! -d "$PROG" ] ; then

    git clone https://github.com/nwdigitalradio/$PROG.git
    if [ "$?" -ne 0 ] ; then
        echo " Problem cloning repository $PROG"
        exit 1
    fi
else
     cd "$SRC_DIR/$PROG"
     # Test if this diretory is really a git repo
     git rev-parse --is-inside-work-tree
     if [ "$?" -ne 0 ] ; then
         echo " Directory: $SRC_DIR/$PROG is not a git repo"
         echo "Change SRC_DIR variable at beginning of this script"
         exit 1
   fi

   git pull
   if [ "$?" -ne 0 ] ; then
      echo "Problem updating repository $PROG"
      exit 1
   fi
fi

if [ "$needs_pkg" = "true" ] ; then
   echo
   echo -e "=== Installing required PACKAGES"

   apt-get install -y -q $INSTALL_PKG_REQUIRE
   if [ "$?" -ne 0 ] ; then
      echo "Package install failed. Please try this command manually:"
      echo "apt-get -y $INSTALL_PKG_REQUIRE"
      exit 1
   fi
   # Update npm
   npm install -g npm
fi

# Check if draws-manager previously installed
cd "$SRC_DIR/$PROG"

files_exist
if [ "$?" -eq 1 ] ; then
    echo "$PROG previously installed, refreshing files ..."
fi

echo "=== Copy config & systemd files"
cp $PROG.service $SYSTEMD_DIR/
cp $PROG /etc/default

echo "=== Start $PROG webapp install"
cd "$SRC_DIR/$PROG/webapp"
/usr/bin/npm install

echo "=== Start $PROG daemon"

service="$PROG"
systemctl is-enabled "$service" > /dev/null 2>&1
if [ $? -ne 0 ] ; then
    echo "ENABLING $service"
    systemctl enable "$service"
    if [ "$?" -ne 0 ] ; then
        echo "Problem ENABLING $service"
    fi
else
    echo "Service $service already enabled"
fi

# Is service alread running?
systemctl is-active "$service"
if [ "$?" -eq 0 ] ; then
    # service is already running, restart it to update config changes
    systemctl restart "$service"
    if [ "$?" -ne 0 ] ; then
        echo "Problem re-starting $service"
    else
        echo "Service $service restarted"
    fi
else
    # service is not yet running so start it up
    systemctl --no-pager start "$service"
    if [ "$?" -ne 0 ] ; then
         echo "Problem starting $service"
    else
         echo "Starting service: $service"
    fi
fi
systemctl --no-pager status $PROG

cd $INITIAL_DIR

echo "$(date "+%Y %m %d %T %Z"): $scriptname: $PROG install script FINISHED" | tee -a $UDR_INSTALL_LOGFILE
echo
