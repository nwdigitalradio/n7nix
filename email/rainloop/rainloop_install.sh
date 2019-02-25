#!/bin/bash
#
# rainloop_install.sh
#
# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"
pkg_name="rainloop"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
SRC_DIR="/usr/local/src/"
TARGET_DIR="/var/www/rainloop"
lighttpdcfg_file="/etc/lighttpd/lighttpd.conf"

num_cores=$(nproc --all)

PHPVER="7.0"
PKG_REQUIRE="php$PHPVER-fpm php$PHPVER php$PHPVER-curl php$PHPVER-xml php-cli php-cgi"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {
dbgecho "Checking package: $1"
return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# ===== function cfg_lighttpd

function cfg_lighttpd() {

    pkg_name="apache2"
    is_pkg_installed $pkg_name
    if [ $? -eq 0 ] ; then
        echo "Remove $pkg_name package"
        apt-get remove -y -q $pkg_name
    fi
    pkg_name="lighttpd"
    is_pkg_installed $pkg_name
    if [ $? -ne 0 ] ; then
        echo "Installing $pkg_name package"
        apt-get install -y -q $pkg_name
    fi

    if [ ! -d "/var/log/lighttpd" ] ; then
        mkdir -p "/var/log/lighttpd"
        touch "/var/log/lighttpd/error.log"
    fi

    chown -R www-data:www-data "/var/log/lighttpd"

    lighttpd-enable-mod fastcgi
    lighttpd-enable-mod fastcgi-php
    ls -l /etc/lighttpd/conf-enabled

    # If you're using lighttpd, add the following to your configuration file:
    cat << 'EOT' >> $lighttpdcfg_file
# deny access to /data directory
$HTTP["url"] =~ "^/data/" {
     url.access-deny = ("")
}
EOT
    # back this file up until verified
    lighttpd_conf_avail_dir="/etc/lighttpd/conf-available"
    cp $lighttpd_conf_avail_dir/15-fastcgi-php.conf $lighttpd_conf_avail_dir/15-fastcgi-php.bak1.conf
    cat << 'EOT' > $lighttpd_conf_avail_dir/15-fastcgi-php.conf
# -*- depends: fastcgi -*-
# /usr/share/doc/lighttpd/fastcgi.txt.gz
# http://redmine.lighttpd.net/projects/lighttpd/wiki/Docs:ConfigurationOptions#mod_fastcgi-fastcgi

## Start an FastCGI server for php (needs the php5-cgi package)
fastcgi.server += ( ".php" =>
        ((
                "socket" => "/var/run/php/php7.0-fpm.sock",
                "broken-scriptfilename" => "enable"
        ))
)
EOT

    # To enable PHP in Lighttpd, must modify /etc/php/7.0/fpm/php.ini
    # and uncomment the line cgi.fix_pathinfo=1:
    php_filename="/etc/php/7.0/fpm/php.ini"
    if [ -e "$php_filename" ] ; then
        sed -i -e '/cgi\.fix_pathinfo=/s/^;//' "$php_filename"
    else
        echo "   ERROR: php config file: $php_filename does not exist"
    fi

    # Change document root directory
    sed -i -e '/server\.document-root / s/server\.document-root .*/server\.document-root = \"\/var\/www\/rainloop\"/' /etc/lighttpd/lighttpd.conf

    # Check for any configuration syntax errors
    lighttpd -t -f /etc/lighttpd/lighttpd.conf

    # Restart lighttpd
    echo "lighttpd force-reload"
    service lighttpd force-reload
}

# ===== main

echo
echo "rainloop install START"

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root."
   exit 1
fi

# Test if rainloop has already been installed.

# Check version of rainloop installed

if [ ! -e "$TARGET_DIR/rainloop" ] ; then
    echo "$scriptname: No rainloop program, installing ..."

    # check if required packages are installed
    dbgecho "Check required packages: $PKG_REQUIRE"
    needs_pkg=false

    for pkg_name in `echo ${PKG_REQUIRE}` ; do

       is_pkg_installed $pkg_name
       if [ $? -ne 0 ] ; then
          echo "$scriptname: Will Install $pkg_name package"
          needs_pkg=true
          break
       fi
    done

    if [ "$needs_pkg" = "true" ] ; then
        echo

        apt-get install -y -q $PKG_REQUIRE
        if [ "$?" -ne 0 ] ; then
            echo "$scriptname: package install failed. Please try this command manually:"
            echo "apt-get install -y $PKG_REQUIRE"
            exit 1
       fi
    fi

    # install lighttpd
    cfg_lighttpd

    echo "=== Install rainloop using $num_cores cores"
    # For testing only, check if zip file exists
    cd "$SRC_DIR"
    if [ ! -e "$SRC_DIR/rainloop-community-latest.zip" ] ; then
        echo "Rainloop src zip does not exist"
        wget https://www.rainloop.net/repository/webmail/rainloop-community-latest.zip
    else
        echo "Found an existing Rainloop src zip"
    fi
    mkdir -p "$TARGET_DIR"
    unzip -q rainloop-community-latest.zip -d "$TARGET_DIR"
    # Grant read/write permissions required by the application:
    cd $TARGET_DIR
    find . -type d -exec chmod 755 {} \;
    find . -type f -exec chmod 644 {} \;

    # Set owner for the app recursively
    chown -R www-data:www-data .
    systemctl daemon-reload

else
    # Display version #

   echo "Found rainloop version: $(cat $TARGET_DIR/data/VERSION)"
fi

echo "$(date "+%Y %m %d %T %Z"): $scriptname: rainloop install script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "rainloop install FINISHED"
echo
