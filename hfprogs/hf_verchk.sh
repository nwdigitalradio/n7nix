#!/bin/bash
#
# Uncomment this statement for debug echos
# DEBUG=1

scriptname="`basename $0`"
user=$(whoami)

# Fpr fl apps use this url
fl_url="http://www.w1hkj.com/files"


function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function display_swap_size

function display_swap_size() {
    swap_size_on=$(swapon -s | tail -n1 | expand -t 1 | tr -s '[[:space:]] ' | cut -d' ' -f3)
    swap_size_on_used=$(swapon -s | tail -n1 | expand -t 1 | tr -s '[[:space:]] ' | cut -d' ' -f4)
    if [ "$swap_size_on_used" -ne "0" ] ; then
        echo "Using swap space: $swap_size_on_used"
    fi
    swap_size_free=$(free | tail -n1 | expand -t 1 | tr -s '[[:space:]] ' | cut -d' ' -f2)
    echo "swap size: $swap_size_on $swap_size_free"
}


# ===== function fl_ver_get

# Get the version of a particular fl application
function fl_ver_get() {

    fl_app="$1"
    ver_url="$fl_url/$fl_app/"

    #curl -s "$ver_url" | grep -i ".tar.gz" | tail -n1 | cut -d '>' -f3 | cut -d '<' -f1
    fl_ver=$(curl -s "$ver_url" | grep -i ".tar.gz" | tail -1 | cut -d '>' -f3 | cut -d '<' -f1 | cut -d '-' -f2)
    fl_ver=$(basename $fl_ver .tar.gz)
}

# ===== function installed_ver_get

# Get the installed version of an application
function installed_ver_get() {
progname="$1"
SRC_DIR="/usr/local/src"

type -P $progname >/dev/null 2>&1
    if [ "$?"  -ne 0 ]; then
        prog_ver="NOT installed"
    else
        if [ "${progname:0:2}" == "fl" ] ; then
            dirname="$(ls -1 $SRC_DIR/$progname*.tar.gz)"
            prog_ver=$(basename $dirname .tar.gz | cut -d '-' -f2)
        else
            dirname="$(ls -1 $SRC_DIR/$progname*.deb)"
            prog_ver=$(basename $dirname .deb | cut -d'_' -f2)
        fi
    fi
}

# ===== function installed_version_display

function installed_version_display() {
    # Get version numbers

    for progname in "js8call" "wsjtx" "fldigi" "flrig" "flmsg" "flamp" ; do
        installed_ver_get "$progname"
        echo "$progname: $prog_ver"
    done
}

# ==== main

if [ ! -z "$DEBUG" ] ; then
    display_swap_size
fi

# installed_version_display

# js8call
if [ -z "$DEBUG1" ] ; then
js8_app="js8call"
#ver_url="https://groups.io/g/js8call/wiki/Download-Links"
#curl  "$ver_url" | grep -A3 -i "RaspberryPi"
#curl "https://groups.io/g/js8call/wiki/Download-Links"

ver_url="https://bitbucket.org/widefido/$js8_app/downloads/?tab=tags"
js8_ver=$(curl -s $ver_url | grep -A1 -i "iterable-item" | head -2 | tail -1 | cut -d'>' -f2 | cut -d '<' -f1)

installed_ver_get "$js8_app"
echo "$js8_app: current version: $js8_ver, installed: $prog_ver"
fi

# wsjtx
if [ -z "$DEBUG1" ] ; then
wsjtx_app="wsjtx"
ver_url="http://physics.princeton.edu/pulsar/K1JT/$wsjtx_app.html"
wsjtx_ver=$(curl -s $ver_url | grep -i "Availability (GA)" | cut -d '>' -f3 | cut -d '<' -f1)
# curl -s $ver_url | grep -i "Availability (GA)" | cut -d '>' -f3 | cut -d '<' -f1
# Remove preceding white space
wsjtx_ver=$(echo ${wsjtx_ver##+([[:space:]])})

installed_ver_get "$wsjtx_app"
echo "$wsjtx_app:   current version: $wsjtx_ver, installed: $prog_ver"
fi

# fldigi
fl_ver_get "fldigi"
installed_ver_get "fldigi"
echo "$fl_app:  current version: $fl_ver, installed: $prog_ver"

# flrig
fl_ver_get "flrig"
installed_ver_get "flrig"
echo "$fl_app:   current version: $fl_ver, installed: $prog_ver"

# flmsg
fl_ver_get "flmsg"
installed_ver_get "flmsg"
echo "$fl_app:   current version: $fl_ver, installed: $prog_ver"

# flamp

fl_ver_get "flamp"
installed_ver_get "flamp"
echo "$fl_app:   current version: $fl_ver, installed: $prog_ver"
