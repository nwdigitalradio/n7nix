#!/bin/bash
#
# Install chattervox from github source repository
#
DEBUG=

USER=$(whoami)
REPO_DIR="/home/$USER/dev/github"
BIN_DIR="/home/$USER/bin"
PROG_NAME="chattervox"
scriptname="`basename $0`"

# ===== function dbgecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function error_exit
# Display string argument & exit

function error_exit() {
	echo "$(tput setaf 1)$1$(tput sgr0)" 1>&2
	exit 1
}

# ===== function is_ax25up
function is_ax25up() {
  ip a show ax0 up > /dev/null  2>&1
}

# ===== function is_direwolf
# Determine if direwolf is running

function is_direwolf() {
    pid=$(pidof direwolf)
}

#
# ===== main
#
# Check for repository directory
if [ ! -e "$REPO_DIR" ] ; then
    mkdir -p "$REPO_DIR"
fi
# Check for local bin directory
if [ ! -e "$BIN_DIR" ] ; then
    mkdir -p "$BIN_DIR"
fi

# Check if AX.25 port ax0 exists & is up
if ! is_ax25up ; then
    echo "$scriptname: AX.25 port not found, ax.25 not running?"
    exit 1
else
    dbgecho "AX.25 is running."
fi

if ! is_direwolf ; then
    echo "$scriptname: direwolf is not running"
    exit 1
else
    dbgecho "Direwolf is running"
fi

# save current directory
pushd $REPO_DIR

if [ -e "$PROG_NAME" ] ; then
    echo
    echo "Found an existing $REPO_DIR/$PROG_NAME, removing"
    echo
    sudo rm -R "$PROG_NAME"

    # Check if chattervox is running
    pidof_main=$(pgrep -f "node build/main.js")
    if [ "$?" -eq 0 ] ; then
        echo "Stopping running $PROG_NAME"
	kill $pidof_main
    fi
fi

# clone the chattervox repo
echo "$(tput setaf 6)Clone $PROG_NAME repo$(tput sgr0)"
git clone https://github.com/brannondorsey/chattervox
if [ "$?" -ne 0 ] ; then
    error_exit "Error cloning $PROG_NAME repo"
fi

cd $PROG_NAME

# Verify latest version of npm
echo "$(tput setaf 6)Get latest version of NPM$(tput sgr0)"
echo "Current npm version: $(npm -v)"

echo "Check for update"
sudo npm install -g npm

# download dependencies
echo "$(tput setaf 6)Download dependencies (npm install)$(tput sgr0)"
npm install
if [ "$?" -ne 0 ] ; then
    error_exit "Error doing npm install"
fi

# transpile the src/*.ts typescript files to build/*.js
echo "$(tput setaf 6)Build $PROG_NAME$(tput sgr0)"
npm run build
if [ "$?" -ne 0 ] ; then
    error_exit "Error on npm run build"
fi

# Verify the key pair exists
echo "$(tput setaf 6)Display keys$(tput sgr0)"
node build/main.js showkey
if [ "$?" -ne 0 ] ; then
    error_exit "Error on $PROG_NAME showkey"
fi

# If configuration files do NOT exist then running the send command will
# prompt for required information & generate an ECDSA keypair
#  ECDSA - Elliptic Curve Digital Signature Algorithm

echo "$(tput setaf 6)Send first test/config message$(tput sgr0)"

node build/main.js send "Install test on $(date)"
if [ "$?" -ne 0 ] ; then
    error_exit "Error on $PROG_NAME send, init call"
fi

# restore initial directory
popd

cp -u chattervox.sh $BIN_DIR

# Reference:
#
# generate a new public/private key pair, and use it as your default signing key
# chattervox genkey --make-signing
#
# run chattervox from source to opening the chat room
# node build/main.js chat
