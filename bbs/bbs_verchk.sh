#!/bin/bash
#
# Uncomment this statement for debug echos
#DEBUG=1

scriptname="`basename $0`"

# Get version number from files web page
ver_url="https://sourceforge.net/projects/linfbb/files/"
#curl -s https://sourceforge.net/projects/linfbb/files/ | grep -i ".tar.gz" | head -n 1 | cut -f2 -d'"'
filename=$(curl -s "$ver_url" | grep -i ".tar.gz" | head -n 1 | cut -f2 -d'"')
if [ "$?" -eq 0 ] ; then
    # filename format ffb-x.x.x.tar.gz
    # remove last 2 extensions
#    basename="${filename%.*}"
#    basename="${basename%.*}"
    basename="$(basename $filename .tar.gz)"
    bbs_latest_ver=$(echo $basename | cut -f2 -d'-')
#    echo "filename: $filename, basename: $basename, version: $bbs_latest_ver"

    # get version number from local source
    local_srcdir="/usr/local/src/fbb*"
    SRCDIR=$(ls -td $local_srcdir | head -n1)
    if [ ! -z $SRCDIR ] ; then
        source_ver=$(grep "AC_INIT(" $SRCDIR/configure.ac | cut -f2 -d ' ' | cut -f1 -d',')
    else
        echo "Could not find source directory: $local_srcdir"
    fi
    installed_ver=$(grep -i ver /usr/local/sbin/fbb | head -n 1 | cut -f2 -d'=')
    echo "fbb: current version: $bbs_latest_ver, source: $source_ver, installed: $installed_ver"

else
    echo "Failed to get linfbb files web page."
    bbs_lastest_ver=
fi
