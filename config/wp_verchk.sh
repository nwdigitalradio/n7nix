#!/bin/bash
#
# Get latest version of WiringPi
WP_GITHUB_VER=
CURRENT_WP_VER="2.60"
SRCDIR=/usr/local/src
GITHUB_VER_FILE="/usr/local/src/WiringPi/VERSION"


# ===== function get_wp_gitver
# Get current version  WiringPi
function get_wp_gitver() {
    pushd $SRCDIR > /dev/null
    if [ -e $SRCDIR/WiringPi ] ; then
        cd WiringPi
	git pull
    else
        git clone https://github.com/WiringPi/WiringPi
    fi
    popd > /dev/null

    if [ -e  $GITHUB_VER_FILE ] ; then
        WP_GITHUB_VER=$(cat $GITHUB_VER_FILE)
    fi
}

# ===== function get_wp_ver
# Get current version of installed WiringPi
function get_wp_ver() {
    wp_ver=$(gpio -v | grep -i "version" | cut -d':' -f2)

    # echo "DEBUG: $wp_ver"
    # Strip leading white space
    # This also works
    # wp_ver=$(echo $wp_ver | tr -s '[[:space:]]')"

    wp_ver="${wp_ver#"${wp_ver%%[![:space:]]*}"}"
}

# ===== main
get_wp_ver
get_wp_gitver
echo "WiringPi current version: $wp_ver, github version: $WP_GITHUB_VER"

LATEST_WP_VER=$CURRENT_WP_VER
if [ ! -z $WP_GITHUB_VER ] ; then
    LATEST_WP_VER=$WP_GITHUB_VER
fi

if [ "$wp_ver" != "$LATEST_WP_VER" ] ; then
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

    get_wp_ver
    echo "WiringPi NEW version: $wp_ver"
fi
