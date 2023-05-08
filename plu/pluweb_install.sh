#!/bin/bash
#
# pluweb_install.sh
#
# Expects NO arguments
# Arg can be one of the following:
#
# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"
SCRIPTNAME="pluweb_install.sh"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
SYSD_DIR="/etc/systemd/system"
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
   dbgecho "$SCRIPTNAME: Verify user name: $USER"
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

# ===== function start_service

function start_service() {
    service="$1"
    systemctl is-enabled "$service" > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "ENABLING $service"
        systemctl enable "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem ENABLING $service"
        fi
    fi
    # Is service alread running?
    systemctl is-active "$service"
    if [ "$?" -eq 0 ] ; then
        # service is already running, restart it to update config changes
        systemctl --no-pager restart "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem re-starting $service"
        fi
    else
        # service is not yet running so start it up
        systemctl --no-pager start "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem starting $service"
        fi
    fi
}

# ===== function node_ver
function node_ver() {

    source /home/$USER/.nvm/nvm.sh

# expect
  #  v19.8.1
  #  0
  #  9.5.1
  #  0
  #  0.39.3
  #  0

if [ ! -z "$DEBUG" ] ; then
    echo "debug:"
    node --version ; echo $? ; npm --version ; echo $? ; nvm --version ; echo $?
fi

    dbgecho "==== Installed versions ===="
    # Display node version
    node_ver=$(node --version)
    node_ret=$?
    if [ $node_ret -eq 0 ] ; then
        # Remove leading 'V'
        node_ver="${node_ver:1}"
        echo "node: $node_ver"
    else
        echo "node NOT installed"
    fi

    # Display npm (Node Package Manager) version
    npm_ver=$(npm --version)
    npm_ret=$?
    if [ $npm_ret -eq 0 ] ; then
        echo "npm: $npm_ver"
    else
        echo "npm NOT installed"
    fi

    # Display nvm (Node Version Manager) version
    nvm_ver=$(nvm --version)
    nvm_ret=$?
    if [ $nvm_ret -eq 0 ] ; then
        echo "nvm: $nvm_ver"
    else
        echo "nvm NOT installed"
    fi
}

# ===== Main

echo -e "\n\tConfigure paclink-unix web server start-up\n"

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root."
   exit 1
fi

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

# Setup node.js & modules required to run the plu web page.
echo
echo " == $SCRIPTNAME: Install nodejs, npm & node modules"

echo "node, npm & nvm need to be installed manually"
# display node version
node_ver

# Don't do this !
if [ 1 -eq 0 ] ; then
    PROGLIST="nodejs npm"
    apt-get install -y -q $PROGLIST
    if [[ $? > 0 ]] ; then
        echo
        echo "$(tput setaf 1)Failed to install $PROGLIST, install from command line. $(tput sgr0)"
        echo
    fi
fi

pushd /usr/local/src/paclink-unix/webapp
sudo chown -R pi:pi .

npm install npm
npm install connect finalhandler serve-static
# Temporary
## Warning "root" does not have permission to access the dev dir #454
## https://github.com/nodejs/node-gyp/issues/454
# sudo npm --unsafe-perm -g install websocket
npm install websocket

echo
echo " == $SCRIPTNAME: Install jquery in directory $(pwd)"
# jquery should be installed in same directory as plu.html
npm install jquery

# rsync -a source/ destination
# rsync -a /home/pi/.nvm/versions/node/v19.8.1/lib/node_modules/ /usr/local/src/paclink-unix/webapp/node_modules

jquery_file="node_modules/jquery/dist/jquery.min.js"
if [ -f "$jquery_file" ] ; then
    cp "$jquery_file"  jquery.js
    echo "   Successfully installed: $jquery_file"
else
    echo
    echo "   $(tput setaf 1)ERROR: file: $jquery_file not found$(tput sgr0)"
    echo
fi

popd > /dev/null


# Set up systemd to run on boot
service="pluweb.service"
echo
echo " == $SCRIPTNAME: Setup systemd for $service"

LOCAL_SYSD_DIR="/home/$USER/n7nix/systemd/sysd"
cp -u $LOCAL_SYSD_DIR/$service $SYSD_DIR
# edit pluweb.service so starts as user

# Check if file exists.
if [ -f "$SYSD_DIR/$service" ] ; then
    dbgecho "Service already exists, comparing $service"
    diff -s $LOCAL_SYSD_DIR/$service $SYSD_DIR/$service
else
    echo "file $SYSD_DIR/$service DOES NOT EXIST"
    exit 1
fi

# Config the User & Group plu-server.js needs to run as
sed -i -e "/User=/ s/User=.*/User=$USER/" $SYSD_DIR/$service
sed -i -e "/Group=/ s/Group=.*/Group=$USER/" $SYSD_DIR/$service

# restart pluweb for new configuration to take affect
echo
echo " == $SCRIPTNAME: Start $service"

start_service $service
systemctl --no-pager status $service

echo
echo "$(date "+%Y %m %d %T %Z"): $SCRIPTNAME: script FINISHED" | tee -a $UDR_INSTALL_LOGFILE
echo
