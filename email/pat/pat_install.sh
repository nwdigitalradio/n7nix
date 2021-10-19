#!/bin/bash
#
# From https://github.com/la5nta/pat/releases
# pat_0.9.0_linux_armhf.deb (Raspberry Pi)
#
# Install FAQ
# https://github.com/la5nta/pat/wiki/Install-FAQ
# Need to edit file: $HOME/.wl2k/config.json
#  mycall
#  secure_login_password
#  locator (Grid square locator ie. CN88nl)
#  hamlib_rigs:
#     "IC-706MKIIG": {"address": "localhost:4532", "network": "tcp"}
#     "K3/KX3": {"address": "localhost:4532", "network": "tcp"}
#  ardop: rig:
#   "rig": "ic-706MKII",
#   "rig": "K3/KX3",
#
# pat connect ardop:///LA1J?freq=3601.5
# pat connect ardop:///K7HTZ?freq=14108.5
#
# requires curl & jq

# These flags get set from command line
DEBUG=
FORCE_INSTALL=


scriptname="`basename $0`"

PAT_CONFIG_FILE="${HOME}/.wl2k/config.json"
PAT_DESKTOP_FILE="$HOME/Desktop/pat.desktop"

## ============ functions ============

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function display_status
function display_status() {

    # Get current version number in repo
    pat_ver="$(curl -s https://raw.githubusercontent.com/la5nta/pat/master/VERSION.go | grep -i "Version = " | cut -f2 -d '"')"
    current_callsign=$(grep -i "\"mycall\":" $PAT_CONFIG_FILE | cut -f2 -d':' | sed -e 's/^[[:space:]]*//' | sed -e 's/\"*//' | cut -f1 -d'"')
    login_password=$(grep -i "\"secure_login_password\":" $PAT_CONFIG_FILE | cut -f2 -d':' | sed -e 's/^[[:space:]]*//' | sed -e 's/\"*//' | cut -f1 -d'"')
    MaidenHead_locator=$(grep -i "\"locator\":" $PAT_CONFIG_FILE | cut -f2 -d':' | sed -e 's/^[[:space:]]*//' | sed -e 's/\"*//' | cut -f1 -d'"')

    # Determine if program has been installed
    progname="pat"
    type -P $progname >/dev/null 2>&1
    if [ "$?"  -ne 0 ]; then
        prog_ver="NOT installed"
    else
        # get installed program version
        prog_ver=$(pat version | cut -f2 -d ' ' | sed 's/[^0-9\.]*//g')
    fi

    echo "PAT: current version: $pat_ver, installed: $prog_ver"
    echo "Call Sign: $current_callsign"
    echo "Winlink login callsign: $login_password"
    echo "Maidenhead locator: $MaidenHead_locator"
}

# ===== function desktop_pat_file

# NOTE: This function is also in ardop/ardop_ctrl.sh
# Use a heredoc to build the Desktop/pat file

function desktop_pat_file() {
    # If running as root do NOT create any user related files
    if [[ $EUID != 0 ]] ; then
        # Set up desktop icon for PAT
        filename=$PAT_DESKTOP_FILE
        if [ ! -e $filename ] ; then

            tee $filename > /dev/null << EOT
[Desktop Entry]
Name=PAT - Mailbox
Type=Link
URL=http://localhost:8080
Icon=/usr/share/icons/PiX/32x32/apps/mail.png
EOT
        else
	    echo "Pat desktop file already exists"
        fi
    else
        echo
        echo " Running as root so PAT desktop file not created"
    fi
}

# ===== function install_pat
function install_pat() {

    read -t 1 -n 10000 discard

    # -p display PROMPT without a trailing new line
    # -e readline is used to obtain the line
    read -ep "Enter call sign, followed by [enter]: " callsign
    read -ep "Enter Winlink Password, followed by [enter]: " login_password
    read -ep "Enter 6 character MaidenHead locator, followed by [enter]: " MaidenHead_locator

    # Get current version number in repo
    patver="$(curl -s https://raw.githubusercontent.com/la5nta/pat/master/VERSION.go | grep -i "Version = " | cut -f2 -d '"')"
    echo " == Downloading pat ver: $patver"

    # Allow a way to test without having to do a download each time
    # No download is done if DEBUG flag is defined
    if [ -z "$DEBUG" ] ; then
        wget https://github.com/la5nta/pat/releases/download/v${patver}/pat_${patver}_linux_armhf.deb
        if [ $?  -ne 0 ] ; then
            echo "Failed getting pat deb file ... exiting"
            exit 1
        else
            echo " == Installpat ver: $patver"
            sudo dpkg -i pat_${patver}_linux_armhf.deb
        fi
    fi

    # Install pat desktop icon file
    desktop_pat_file

    # Write 3 config variables to PAT config file
    jq --arg pw "${login_password}" --arg loc "${MaidenHead_locator}" --arg call "${callsign}" '.mycall = $call | .secure_login_password = $pw | .locator = $loc' $PAT_CONFIG_FILE  > temp.$$.json
    echo "jq ret code: $?"
    echo "Updating PAT config file: $PAT_CONFIG_FILE"
    mv temp.$$.json $PAT_CONFIG_FILE

    # Edit Config file: jq does not support in-place editing, so you must
    # redirect to a temporary file first and then replace your original
    # file with it, or use sponge utility from the moreutils package.
    #
    # $$ is the process id of the shell in which your script is
    #    running.
    #
    # Strings:
    #  jq --arg a "${address}" '.address = $a' test.json > "tmp" && mv "tmp" test.json
    #
    # Integers:
    #  jq --argjson a "${age}" '.age = $a' test.json > "tmp" && mv "tmp" test.json
    #
    # address=abcde
    # jq --arg a "$address" '.address = $a' test.json > "$tmp" && mv "$tmp" test.json


}

# ===== Display program help info

function usage () {
	(
	echo "Usage: $scriptname [-f][-d][-h]"
        echo "    -f | --force   force update of sensor config file"
        echo "    -s | --status  display PAT config information"
        echo "    -d | --debug   turn on debug display"
        echo "    -h | --help    display this message."
        echo
	) 1>&2
	exit 1
}

# ===== main

# Don't be root
if [[ $EUID == 0 ]] ; then
    echo "$scriptname: Do NOT need to run as root."
    exit 0
fi

# if there are any args then parse them
while [[ $# -gt 0 ]] ; do
   key="$1"

   case $key in
      -d|--debug)   # set DEBUG flag
         DEBUG=1
         echo "Set DEBUG flag"
         ;;
      -f|--force)
         FORCE_INSTALL=1
         echo "Set FORCE_INSTALL flag"
         ;;
      -s|--status)
         display_status
         exit 0
         ;;
      -h|--help)
         usage
	 exit 0
	 ;;
      *)
	echo "Unknown option: $key"
	usage
	exit 1
	;;
   esac
shift # past argument or value
done


if [ -e "$PAT_CONFIG_FILE" ] ; then
    # get callsign from PAT config file
    current_callsign=$(grep -i "\"mycall\":" $PAT_CONFIG_FILE | cut -f2 -d':' | sed -e 's/^[[:space:]]*//' | sed -e 's/\"*//' | cut -f1 -d'"')

    if [ -z $current_callsign ] || [ "$FORCE_INSTALL" = 1 ] ; then
        echo "Installing PAT"
        install_pat
    else
        echo "PAT config file ALREADY exists, use -f option to force another install."
	exit 0
    fi
fi

exit 0
