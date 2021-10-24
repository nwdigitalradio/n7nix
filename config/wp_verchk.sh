#!/bin/bash
#
# Get latest version of WiringPi

WP_GITHUB_VER=
CURRENT_WP_VER="2.60"
SRCDIR=/usr/local/src
GITHUB_VER_FILE="/usr/local/src/WiringPi/VERSION"

scriptname="`basename $0`"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function get_wp_gitver
# Get current version  WiringPi

function get_wp_gitver() {
    pushd $SRCDIR > /dev/null
    if [ -e $SRCDIR/WiringPi ] ; then
        cd WiringPi
	git pull --quiet
    else
        git clone https://github.com/WiringPi/WiringPi
    fi
    popd > /dev/null

    if [ -e  $GITHUB_VER_FILE ] ; then
        WP_GITHUB_VER=$(cat $GITHUB_VER_FILE)
    fi
}

# ===== function get_installed_wp_ver
# Get current version of installed WiringPi
function get_installed_wp_ver() {

    type -P $progname  >/dev/null 2>&1
    if [ "$?"  -ne 0 ]; then
        installed_wp_ver="NOT installed"
    else
        dbgecho "Found $progname"

        installed_wp_ver=$($progname -v | grep -i "version" | cut -d':' -f2)

        # echo "DEBUG: $installed_wp_ver"

        # Remove preceeding white space, Strip leading white space

        # This also works
        # installed_wp_ver=$(echo $installed_wp_ver | tr -s '[[:space:]]')"
        # installed_wp_ver=$(sed -e 's/^[[:space:]]*//' <<< "$installed_wp_ver")

        installed_wp_ver="${installed_wp_ver#"${installed_wp_ver%%[![:space:]]*}"}"
    fi
}

# ===== Display program help info
#
usage () {
	(
	echo "Usage: $scriptname [-u][-l][-h]"
        echo "    No arguments displays current & installed versions."
        echo "    -u Set application update flag."
        echo "       Update source, build & install."
        echo "    -l display local version only."
        echo "    -h display this message."
        echo
	) 1>&2
	exit 1
}


# ===== main

progname="gpio"

# Check for any command line arguments
# Command line args are passed with a dash & single letter
#  See usage function

while [[ $# -gt 0 ]] ; do

    key="$1"
    case $key in
        -d)
            DEBUG=1
        ;;
        -l)
            dbgecho "Display local version only."
            get_installed_wp_ver
            echo "$progname: $installed_wp_ver"
            exit
        ;;
        -u)
            dbgecho "Update WiringPi gpio after checking version numbers."
            UPDATE_FLAG=true
        ;;
        -h)
            usage
            exit 0
        ;;
        *)
            echo "Undefined argument: $key"
            usage
            exit 1
        ;;
    esac
    shift # past argument or value
done

get_installed_wp_ver
get_wp_gitver
echo "WiringPi installed version: $installed_wp_ver, github version: $WP_GITHUB_VER"

LATEST_WP_VER=$CURRENT_WP_VER
if [ ! -z $WP_GITHUB_VER ] ; then
    LATEST_WP_VER=$WP_GITHUB_VER
fi

dbgecho "vers: installed: -$installed_wp_ver-, github: -$WP_GITHUB_VER-, latest: -$LATEST_WP_VER-, current: -$CURRENT_WP_VER-"

if [ "$installed_wp_ver" != "$LATEST_WP_VER" ] ; then
    echo "Installing latest version of WiringPi"
    # Setup tmp directory
    if [ ! -d "$SRCDIR" ] ; then
        mkdir "$SRCDIR"
    fi

    # The following no longer works to update wiringpi
    # wget https://project-downloads.drogon.net/wiringpi-latest.deb
    # sudo dpkg -i wiringpi-latest.deb

    # Build WiringPi from source
    pushd $SRCDIR > /dev/null
    # Repo already created or refreshed in get_wp_gitver()
#    git clone https://github.com/WiringPi/WiringPi
    cd WiringPi
    ./build
    gpio -v
    popd > /dev/null

    get_installed_wp_ver
    echo "WiringPi NEW version: $installed_wp_ver"
fi
