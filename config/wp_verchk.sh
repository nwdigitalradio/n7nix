#!/bin/bash
#
# Get latest version of WiringPi
CURRENT_VER="2.52"
TMPDIR=$HOME/tmp

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

# ===== main
get_wp_ver
echo "WiringPi version: $wp_ver"
if [ "$wp_ver" != "$CURRENT_VER" ] ; then
    echo "Installing latest version of WiringPi"
    # Setup tmp directory
    if [ ! -d "$TMPDIR" ] ; then
        mkdir "$TMPDIR"
    fi

    pushd $TMPDIR
    wget https://project-downloads.drogon.net/wiringpi-latest.deb
    sudo dpkg -i wiringpi-latest.deb
    popd > /dev/null

    get_wp_ver
    echo "New WiringPi version: $wp_ver"
fi
