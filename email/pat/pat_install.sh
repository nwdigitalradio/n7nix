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
# Set this variable to prevent downloading PAT package (for development)
SPECIAL_DEBUG=

# These flags get set from command line
DEBUG=
FORCE_INSTALL=

PKG_REQUIRE="jq curl"

scriptname="`basename $0`"

PAT_CONFIG_FILE_1="${HOME}/.wl2k/config.json"
# OR
PAT_CONFIG_FILE_2="${HOME}/.config/pat/config.json"

PAT_CONFIG_FILE=


PAT_DESKTOP_FILE="$HOME/Desktop/pat.desktop"

## ============ functions ============

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {
   return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed")
}


# ===== function check_required_packages

function check_required_packages() {
    # check if required packages are installed
    dbgecho "Check packages: $PKG_REQUIRE"
    needs_pkg=false

    for pkg_name in `echo ${PKG_REQUIRE}` ; do

       is_pkg_installed $pkg_name
       if [ $? -eq 0 ] ; then
          echo "$myname: Will Install $pkg_name program"
          needs_pkg=true
          break
       fi
    done

    if [ "$needs_pkg" = "true" ] ; then

        sudo apt-get install -y -q $PKG_REQUIRE
        if [ "$?" -ne 0 ] ; then
            echo "Required package install failed. Please try this command manually:"
            echo "apt-get install -y $PKG_REQUIRE"
            exit 1
       fi
    fi
}

# ===== function get_installed_pat_ver
# get currently installed version

function get_installed_pat_ver() {

    progname="pat"

    # Determine if program has been installed
    type -P $progname  >/dev/null 2>&1
    if [ "$?"  -ne 0 ]; then
        installed_pat_ver="NOT installed"
    else
        installed_pat_ver=$(pat version | cut -f2 -d ' ' | sed 's/[^0-9\.]*//g')
    fi
}

# ===== function check_pat_ver

function check_pat_ver() {
    dbgecho "DEBUG: Entering ${FUNCNAME[0]}"
    # Get current version number in repo
    # pat_ver="$(curl -s https://raw.githubusercontent.com/la5nta/pat/master/VERSION.go | grep -i "Version = " | cut -f2 -d '"')"
    pat_ver=$(curl -s https://raw.githubusercontent.com/la5nta/pat/master/internal/buildinfo/VERSION.go | grep -i "Version = " | cut -f2 -d '"')

    get_installed_pat_ver
}

# ===== function check_pat_config_file
#
# Set PAT_CONFIG_FILE variable

function check_pat_config_file() {

    dbgecho "${FUNCNAME[0]}: PAT config file location check"

    cnt_found_cfg_file=0

    if [ -e "$PAT_CONFIG_FILE_1" ] ; then
        dbgecho "Found PAT config file in .wl2k directory"
        (( cnt_found_cfg_file++ ))
        PAT_CONFIG_FILE="$PAT_CONFIG_FILE_1"
    fi

    if [ -e "$PAT_CONFIG_FILE_2" ] ; then
        dbgecho "Found PAT config file in .config/pat directory"
        (( cnt_found_cfg_file++ ))

        # If 2 config files found default to using ./config/pat/config.json
        PAT_CONFIG_FILE="$PAT_CONFIG_FILE_2"
    fi

    if (( cnt_found_cfg_file == 2 )) ; then
        echo "WARNING: Found 2 PAT config files"
    fi

    if [ ! -z $PAT_CONFIG_FILE ] ; then
	echo "Using PAT config file: $PAT_CONFIG_FILE"
    else
        echo "NO PAT config file found."
    fi
}

# ===== function check_pat_cfg
#
# Set current_callsign variable to determine if config is new

function check_pat_cfg() {
    dbgecho "DEBUG: Entering ${FUNCNAME[0]}"
    retcode=0
    current_callsign=

    if [ -e "$PAT_CONFIG_FILE" ] ; then

        dbgecho "${FUNCNAME[0]}: pat config file: $PAT_CONFIG_FILE"
        # get callsign from PAT config file
        current_callsign=$(grep -i "\"mycall\":" $PAT_CONFIG_FILE | cut -f2 -d':' | sed -e 's/^[[:space:]]*//' | cut -f2 -d'"')
    else
        echo
        echo "NO PAT config file found after install"
	echo "WILL RUN: pat configure"
	echo
	retcode=1
    fi
    dbgecho "${FUNCNAME[0]}: pat call sign: $current_callsign"

    return $retcode
}

# ===== function config_file_main

function config_file_main() {

    dbgecho "DEBUG: Entering ${FUNCNAME[0]}"
    # Check for location of PAT configuration file
    check_pat_config_file
    # Check if config file has ever been configured
    check_pat_cfg
    if [ ! -z $current_callsign ] ; then
        echo "PAT config file ALREADY exists and his been previously configured"
        read -t 1 -n 10000 discard
	read -p "Continue to edit (Y or N): " -n 1 -r REPLY
	echo
        if [[ ! "$REPLY" =~ ^[Yy]$ ]] ; then
            echo
            echo "PAT config file unchanged."
            echo
        fi
    fi
}

# ===== function display_status
function display_status() {

    check_pat_ver
    echo "PAT: current version: $pat_ver, installed: $installed_pat_ver"

    # Check which PAT config file is being used
    check_pat_config_file

    if [ ! -z "$PAT_CONFIG_FILE" ] ; then
        # current_callsign=$(grep -i "\"mycall\":" $PAT_CONFIG_FILE | cut -f2 -d':' | sed -e 's/^[[:space:]]*//' | sed -e 's/\"*//' | cut -f1 -d'"')
        # login_password=$(grep -i "\"secure_login_password\":" $PAT_CONFIG_FILE | cut -f2 -d':' | sed -e 's/^[[:space:]]*//' | sed -e 's/\"*//' | cut -f1 -d'"')
        # MaidenHead_locator=$(grep -i "\"locator\":" $PAT_CONFIG_FILE | cut -f2 -d':' | sed -e 's/^[[:space:]]*//' | sed -e 's/\"*//' | cut -f1 -d'"')

        current_callsign=$(grep -i "\"mycall\":" $PAT_CONFIG_FILE | cut -f2 -d':' | sed -e 's/^[[:space:]]*//' | cut -f2 -d'"')
        login_password=$(grep -i "\"secure_login_password\":" $PAT_CONFIG_FILE | cut -f2 -d':' | sed -e 's/^[[:space:]]*//' | cut -f2 -d'"')
        MaidenHead_locator=$(grep -i "\"locator\":" $PAT_CONFIG_FILE | cut -f2 -d':' | sed -e 's/^[[:space:]]*//' | cut -f2 -d'"')
	if [ -z "$current_callsign" ] ; then
	    echo "PAT NOT configured"
	else
            echo "Call Sign: $current_callsign"
            echo "Winlink login password: $login_password"
            echo "Maidenhead locator: $MaidenHead_locator"
	fi
    else
        echo
	echo "PAT config file does not exist"
    fi
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

# ===== function pat_config_file_edit

function pat_config_file_edit() {

    dbgecho "Basic config for file: $PAT_CONFIG_FILE"
    # Flush the read buffer
    read -t 1 -n 10000 discard

    # -p display PROMPT without a trailing new line
    # -e readline is used to obtain the line
    read -ep "Enter call sign, followed by [enter]: " CALLSIGN
    # Convert callsign to upper case
    CALLSIGN=$(echo "$CALLSIGN" | tr '[a-z]' '[A-Z]')

    read -ep "Enter Winlink Password, followed by [enter]: " login_password
    read -ep "Enter 6 character MaidenHead locator, followed by [enter]: " MaidenHead_locator

    # Write 3 config variables to PAT config file
    jq --arg pw "${login_password}" --arg loc "${MaidenHead_locator}" --arg call "${CALLSIGN}" '.mycall = $call | .secure_login_password = $pw | .locator = $loc' $PAT_CONFIG_FILE  > temp.$$.json
    dbgecho "jq ret code: $?"
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

# ===== config_pat

function config_pat() {

    if [ ! -z "$PAT_CONFIG_FILE" ] ; then
        pat_config_file_edit
    else
	# Only if building from source
        #  go get -tags 'libax25 libhamlib' github.com/la5nta/pat
        #  TAGS="libax25 libhamlib" ./make.bash

        echo
        echo "Select editor to use for 'pat configure'"
        sudo update-alternatives --config editor

	if [ -e "$HOME/.selected_editor" ] ; then
            EDITOR=$(cat $HOME/.selected_editor | tail -n 1 |  cut -f2 -d"=")
	else
	    EDITOR=$(echo "$(basename  $(readlink /etc/alternatives/editor))")
	fi

        if [ 1 -eq 1 ] ; then
            # echo "Edit PAT config file using $(editor --version | head -n 1)"
            # echo "PAT config file will not exist until after the first time PAT is run."
            echo "Running 'pat configure' JUST to create config file."
            echo "Edit PAT config file using $EDITOR"
	    echo
	    echo "$(tput setaf 1) PLEASE EXIT editor immediately$(tput sgr0)"
	    echo
	    # Wait a couple of seconds to read above message
	    sleep 2
	    sh -c "pat configure"
#            read -t 1 -n 10000 discard

	    PAT_CONFIG_FILE="$PAT_CONFIG_FILE_2"
            echo "${FUNCNAME[0]}: Editing PAT config file: $PAT_CONFIG_FILE with sed"
	    pat_config_file_edit
        else
	    echo "NOT Editing PAT config file using $EDITOR, does NOT work yet"
	fi
    fi
    dbgecho "DEBUG: Leaving ${FUNCNAME[0]}"
}

# ==== function get_mach_hardware
# Set variable $suffix to either amd64 or armhf

function get_mach_hardware() {
    # For RPi 32 bit
    # pat_0.15.0_linux_armhf.deb (Raspberry Pi 32-bit)
    #
    # For 64 bit Intel
    # pat_0.15.0_linux_amd64.deb

    # uname -m
    # x86_64
    # armv7l
    # aarch64

    mach_hardware="$(uname -m)"

    suffix=
    case $mach_hardware in

        "x86_64")
            suffix="amd64"
        ;;
        "armv7l")
            suffix="armhf"
        ;;
        "aarch64")
	# NOTE: arm64 architecture will not work for this package
	#  Use 32 bit version
        #   suffix="arm64"
	    echo
	    echo "NOTE: 64 bit arch does NOT work, forcing 32 bit arch"
	    echo
            suffix="armhf"
        ;;
        *)
            suffix="unknown"
            echo "Undefined machine hardware: $mach_hardware, exiting."
	    exit 1
        ;;
    esac

    echo "machine architecture: $mach_hardware, suffix: $suffix"
}

# ===== function download_pat
# Downloads current PAT deb file & installs it
function download_pat() {
    # Allow a way to test without having to do a download of the deb
    # file each time. No download is done if DEBUG flag is defined

    get_mach_hardware

    if [ -z "$SPECIAL_DEBUG" ] ; then
        wget https://github.com/la5nta/pat/releases/download/v${pat_ver}/pat_${pat_ver}_linux_${suffix}.deb
        if [ $?  -ne 0 ] ; then
            echo "Failed getting pat deb file ... exiting"
            exit 1
        fi
    else
        echo "DEBUG flag set so no download of a fresh Debian install file."
    fi
    echo " == Installing pat ver: $pat_ver"
    sudo dpkg -i pat_${pat_ver}_linux_${suffix}.deb
    dbgecho "DEBUG: install check: $(which pat)"
}

# ===== function install_pat
function install_pat() {

    echo "${FUNCNAME[0]}: Checking PAT configuration"
    check_pat_ver
    if [ -z "$pat_ver" ] ; then
        echo
        echo "Could not find a valid PAT version from github file."
	echo
	exit 1
    fi

    if [ "$pat_ver" == "$installed_pat_ver" ] ; then
        echo "Installed PAT version: $installed_pat_ver is current."
        # Check if FORCE flag has been set
        if [ ! -z "$FORCE_INSTALL" ] ; then
            echo " == Force downloading pat ver: $pat_ver"
	    download_pat
        fi
    else
        echo "Installed PAT version: $installed_pat_ver is different from current version: $pat_ver."
        echo " == Downloading pat ver: $pat_ver"
        download_pat
    fi

    dbgecho "DEBUG: check for desktop file"
    # Install pat desktop icon file
    desktop_pat_file

    dbgecho "DEBUG: check for config file"
    # Check if config file has ever been configured
    check_pat_cfg
    ret_code=$?
#    if [ -z $current_callsign ] ; then
     if [[ "$ret_code" -eq 1 ]] ; then
        dbgecho "DEBUG: no config file found"
        config_pat
    else
        # Found a PAT config file
       dbgecho "DEBUG: Found a config file, check for callsign in config file"
       if [ -z $current_callsign ] ; then
           echo  "Edit PAT config.json file"
           config_pat
        else
           echo "Found call sign: $current_callsign"
        fi
    fi
}

# ===== Display program help info

function usage () {
	(
	echo "Usage: $scriptname [-f][-d][-h]"
	echo "    -c | --config  Initial config edit"
	echo "    -r | --remove  Completely remove PAT package"
        echo "    -f | --force   force update/install of PAT"
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
        -c|--config)
            config_file_main
	    # Prompt for call sign, Winlink password, Maidenhead locator
	    pat_config_file_edit
	    echo
	    display_status
	    exit 0
	;;
        -r|--remove)
            sudo dpkg --purge pat
	    echo
	    echo "Removing PAT config file"
            if [ -e "$PAT_CONFIG_FILE_1" ] ; then
                dbgecho "Found PAT config file in .wl2k directory"
		rm -R ~/.wl2k
            fi
            if [ -e "$PAT_CONFIG_FILE_2" ] ; then
                dbgecho "Found PAT config file in .config/pat directory"
		rm -R ~/.config/pat
            fi

	    # Check for location of PAT configuration file
	    check_pat_config_file
	    exit 0
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
	-t)
	    echo "START test"
	    echo
	    check_pat_config_file
	    pat configure
	    echo "return val: $?"
	    echo
	    echo "END test"
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

check_required_packages

# Check for location of PAT configuration file
dbgecho "${FUNCNAME[0]}: DEBUG: check_pat_config_file enter: $PAT_CONFIG_FILE"
check_pat_config_file
dbgecho "${FUNCNAME[0]}: DEBUG: check_pat_config_file exit: $PAT_CONFIG_FILE"


if [ ! -z "$PAT_CONFIG_FILE" ] ; then
    # Get here if PAT config file exists
    # Set current_callsign variable from PAT config file
    current_callsign=

    if [ -e "$PAT_CONFIG_FILE" ] ; then
        dbgecho "${FUNCNAME[0]}: pat config file: $PAT_CONFIG_FILE"
        # get callsign from PAT config file
        current_callsign=$(grep -i "\"mycall\":" $PAT_CONFIG_FILE | cut -f2 -d':' | sed -e 's/^[[:space:]]*//' | cut -f2 -d'"')
    fi

    dbgecho "${FUNCNAME[0]}: after check_pat_cfg"
    # Set pat_ver & installed_pat_ver variables
    check_pat_ver

    # Init exit_now flag
    exit_now=0
    if [ "$pat_ver" == "$installed_pat_ver" ] ; then
        echo "Installed PAT version: $installed_pat_ver is current."
	exit_now=1
    fi
    if [ ! -z $current_callsign ] ; then
        echo "PAT config file ALREADY exists and has been previously configured"
	exit_now=1
    fi

    if [ ! -z "$FORCE_INSTALL" ] ; then
        echo
        echo "$(tput setaf 6)PAT config file DOES exist, installing PAT$(tput sgr0)"
        echo
        install_pat
#	config_file_main
        display_status
    else
        # Will fall through to exit
        echo "Can use -f command line option to force another install."
    fi
else
    echo
    echo "$(tput setaf 4)PAT config file does NOT exist, installing PAT$(tput sgr0)"
    echo
    install_pat
#    config_file_main
    display_status
fi

exit 0
