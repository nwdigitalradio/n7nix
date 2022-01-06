#!/bin/bash
#
# Expects an argument for which app to install
# Arg can be one of the following:
#	core, rmsgw, plu, plumin
#
# Uncomment this statement for debug echos
# DEBUG=1

scriptname="`basename $0`"

# Get latest version of WiringPi
CURRENT_WP_VER="2.60"
SRCDIR=/usr/local/src

UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

CALLSIGN="N0ONE"
USER=
APP_CHOICES="core, rmsgw, plu, test"
APP_SELECT=

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function usage
function usage() {
   echo "Usage: $scriptname [-d][-h][core][plu][plumin][rmsgw]" >&2
   echo "   core      MUST be run before any other config"
   echo "   plu       Configures paclink-unix & webmail with dovecot"
   echo "   plumin    Configures paclink-unix & mutt"
   echo "   rmsgw     Configures Linux RMS Gateway"
#   echo "   messenger Configures messenger appliance"
   echo "   -d        set debug flag"
   echo "   -h        no arg, display this message"
   echo
}

# ===== function get_callsign

function get_callsign() {

if [ "$CALLSIGN" == "N0ONE" ] ; then
   read -t 1 -n 10000 discard
   echo -n "Enter call sign, followed by [enter]"
    # -p display PROMPT without a trailing new line
    # -e readline is used to obtain the line
   read -ep ": " CALLSIGN

   sizecallstr=${#CALLSIGN}

   if (( sizecallstr > 6 )) || ((sizecallstr < 3 )) ; then
      echo "Invalid call sign: $CALLSIGN, length = $sizecallstr"
      return 0
   fi

   # Convert callsign to upper case
   CALLSIGN=$(echo "$CALLSIGN" | tr '[a-z]' '[A-Z]')
fi

dbgecho "Using CALL SIGN: $CALLSIGN"
return 1
}
# ===== function get_user

function get_user() {
   # Check if there is only a single user on this system
   if (( `ls /home | wc -l` == 1 )) ; then
      USER=$(ls /home)
   else
      echo -n "Enter user name ($(echo $USERLIST | tr '\n' ' ')), followed by [enter]"
      read -ep ": " USER
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

# ===== function CopyDesktopFiles

function CopyDesktopFiles() {

    ax25_desktop_file="/home/$USER/Desktop/ax25-startstop.desktop"

    # Check if direwolf is running.
    pid=$(pidof direwolf)
    if [ $? -eq 0 ] ; then
        # Direwolf IS running copy off icon
        sudo -u $USER cp -u /home/$USER/n7nix/ax25/icons/ax25-stop.desktop "$ax25_desktop_file"
    else
        # Direwolf is NOT running copy on icon
        sudo -u $USER cp -u /home/$USER/n7nix/ax25/icons/ax25-start.desktop "$ax25_desktop_file"
    fi
    # Copy the desktop files to a common directory
    sudo -u $USER cp -u /home/$USER/n7nix/ax25/icons/*.desktop /home/$USER/bin
    # Copy both white back-ground & no back-ground icons
    sudo cp -u /home/$USER/n7nix/ax25/icons/*.png /usr/share/pixmaps/
    sudo cp -u /home/$USER/n7nix/ax25/icons/*.svg /usr/share/pixmaps/

    echo
    echo "copying desktop files FINISHED"
}

# ===== function get_wp_ver
# Get current version of WiringPi
function get_wp_ver() {
    wp_ver=$(gpio -v | grep -i "version" | cut -d':' -f2)

    # echo "DEBUG: $wp_ver"
    # Strip leading white space
    # This also works
    # wp_ver=$(echo $wp_ver | tr -s '[[:space:]]')"

    wp_ver="${wp_ver#"${wp_ver%%[![:space:]]*}"}"
}

# ===== function chk_wp_ver
# Check that the latest version of WiringPi is installed
function chk_wp_ver() {
    get_wp_ver
    echo "WiringPi version: $wp_ver"
    if [ "$wp_ver" != "$CURRENT_WP_VER" ] ; then
        echo "Installing latest version of WiringPi"
        # Setup tmp directory
        if [ ! -d "$SRCDIR" ] ; then
            mkdir "$SRCDIR"
        fi

        # Need wiringPi version 2.60 for Raspberry Pi 400 which is not yet
        # in Debian repos.
        # The following does not work.
        #   wget -P /usr/local/src https://project-downloads.drogon.net/wiringpi-latest.deb
        #   sudo dpkg -i /usr/local/src/wiringpi-latest.deb

        pushd $SRCDIR
        git clone https://github.com/WiringPi/WiringPi
        cd WiringPi
        ./build
        gpio -v
        popd > /dev/null

        get_wp_ver
        echo "New WiringPi version: $wp_ver"
    fi
}

# ===== function refresh bindir
# Update the local bin dir
function refresh_bindir() {
    echo
    echo "Update local bin directory for user: $USER"
    cd "$START_DIR"
    program_name="/home/$USER/bin/bin_refresh.sh"
    type -P "$program_name"  &>/dev/null
    if [ $? -eq 0 ] ; then
        echo "script: ${program_name} found"
        sudo -u "$USER" $program_name
    else
        echo -e "\n\t$(tput setaf 1)script: ${program_name} NOT installed for user $(whoami) $(tput setaf 7)\n"
    fi
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
    return $retcode
}

# ===== function get_hostname
# Validate hostname
#   https://stackoverflow.com/questions/20763980/check-if-a-string-contains-only-specified-characters-including-underscores/20764037

function get_hostname() {

    #  Clear the read buffer
    read -t 1 -n 10000 discard

    read -ep "Enter new host name followed by [enter]: " HOSTNAME

    # From hostname(7) man page
    # Valid characters for hostnames are ASCII(7) letters from a to z,
    # the digits from 0 to 9, and the hyphen (-).
    # A hostname may not start with a hyphen.
    if [[ $HOSTNAME =~ ^[a-z0-9\-]+$ ]]; then
        dbgecho "str: $HOSTNAME  matches"
        return 0
    else
        dbgecho "str: $HOSTNAME does NOT match"
        return 1
    fi
}

# ===== function set_hostname
# Change host machine name in these files:
# - /etc/hostname
# - /etc/mailname
# - /etc/hosts

function set_hostname() {

    hostname_default="draws"
    HOSTNAME=$(cat /etc/hostname | tail -1)

    # Check hostname
    echo "=== Verify current hostname: $HOSTNAME"

    # Check for any of the default hostnames
    if ! is_hostname  ; then

        echo "Current host name: $HOSTNAME, change it"

        # Change hostname
        while  ! get_hostname ; do
            echo "Input error for: $HOSTNAME, try again"
            echo "Valid characters for hostnames are:"
            echo " letters from a to z,"
            echo " the digits from 0 to 9,"
            echo " and the hyphen (-)"
        done

        if [ ! -z "$HOSTNAME" ] ; then
            echo "Setting new hostname: $HOSTNAME"
        else
            echo "Setting hostname to default: $hostname_default"
            HOSTNAME="$hostname_default"
        fi
        # echo "$HOSTNAME" > /etc/hostname
        echo "$HOSTNAME" | sudo tee /etc/hostname > /dev/null
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
}

# ===== main

echo "$scriptname: script start"

# Get current working directory
START_DIR=$(pwd)

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "$scriptname: Must be root"
   exit 1
fi

# Check if there are any args on command line
if (( $# == 0 )) ; then
    echo "No app chosen from command arg, exiting"
    usage
    exit 1
fi

# check for control arguments passed to this script

APP_SELECT="$1"

while [[ $# -gt 0 ]] ; do
APP_ARG="$1"

case $APP_ARG in

   -d|--debug)
      DEBUG=1
      echo "Debug mode on"
   ;;
   -h|--help|?)
      usage
      exit 0
   ;;
   *)
      break;
   ;;

esac

shift # past argument
done

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

get_user
check_user

# Check again if there are any remaining args on command line
if (( $# == 0 )) ; then
    echo "No app chosen from command arg, exiting"
    usage
    exit 1
fi

# Get call sign if not doing a test
if [ "$APP_SELECT" != "test" ] ; then
    # prompt for a callsign
    while get_callsign ; do
        echo "Input error, try again"
    done
fi

# parse command args for app to config

while [[ $# -gt 0 ]] ; do
APP_SELECT="$1"

case $APP_SELECT in

   core)
      echo "$scriptname: Config core"
      # configure core
      source ./core_config.sh

      # configure ax25
      # Needs a callsign
      pushd ../ax25
      source ./config.sh $USER $CALLSIGN
      popd > /dev/null

      # configure direwolf
      # Needs a callsign
      pushd ../direwolf
      source ./config.sh $CALLSIGN
      popd > /dev/null

      # configure systemd
      pushd ../systemd
      /bin/bash ./install.sh
      /bin/bash ./config.sh
      popd > /dev/null

      # configure iptables
      pushd ../iptables
      /bin/bash ./iptable_install.sh $USER
      popd > /dev/null

      # copy desktop icon files
      CopyDesktopFiles

      # Fix for 'file Manager instantly closes when opened' bug
      echo "Update file manager pcmanfm"
      apt-get install -y -q --reinstall pcmanfm

      # Check for latest verion of WiringPi
      chk_wp_ver

      # Update local bin dir
      refresh_bindir

      # Set new hostname as last action to prevent a bunch of 'unable to resolve host' errors
      set_hostname
      # Need a reboot after this
      echo
      echo "core configuration FINISHED, need to reboot"
   ;;
   rmsgw)
      # Configure rmsgw
      echo "Configure RMS Gateway"
      # needs a callsign
      source ../rmsgw/config.sh $CALLSIGN
   ;;
   plu)
      # Config paclink-unix with 3 email apps, mutt claws & rainloop
      #  Also install postfix, dovecot, lighttpd
      # This configures mutt & postfix
      echo "$scriptname: Config paclink-unix with claws, dovecot & rainloop install"
      pushd ../plu
      source ./plu_config.sh $USER $CALLSIGN
      popd > /dev/null

      # This sets up systemd to start web server for paclink-unix
      pushd ../plu
      source ./pluweb_install.sh $USER
      popd > /dev/null

      # configure dovecot
      pushd ../email/claws
      source ./dovecot_config.sh $USER
      popd > /dev/null

      # This installs rainloop & lighttpd
      pushd ../email/rainloop
      source ./rainloop_install.sh
      popd > /dev/null

      # This installs claws-mail
      pushd ../email/claws
      sudo -u "$USER" ./claws_install.sh $USER $CALLSIGN
      popd > /dev/null
   ;;
    # Just install paclink-unix, postfix & mutt for headless apps like rms gateway
   plumin)
      echo "$scriptname: Config minimum paclink-unix"
      pushd ../plu
      source ./plu_config.sh $USER $CALLSIGN
      popd > /dev/null
   ;;
#   messenger)
#      echo "$scriptname: Config messenger appliance"
#      pushd ../plu
#      source ./pluimap_config.sh -
#      popd > /dev/null
#   ;;
   test)
      echo
      echo " ===== $scriptname: Test setting up AX.25 IP Address"
      echo
      source ./setax25-ipaddr.sh
   ;;
   *)
      echo "Undefined app, must be one of $APP_CHOICES"
      echo "$(date "+%Y %m %d %T %Z"): app install ($APP_SELECT) script ERROR, undefined app" >> $UDR_INSTALL_LOGFILE
      exit 1
   ;;
esac

shift # past argument or value
done

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: app config ($APP_SELECT) script FINISHED" | tee -a $UDR_INSTALL_LOGFILE
echo
