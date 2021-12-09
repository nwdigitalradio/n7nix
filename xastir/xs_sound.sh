#!/bin/bash
# Verify where sound files are
# Seems to be a problem if compiled
# /usr/local/share/xastir/sounds does not seem to work

scriptname="$(basename $0)"
xastirpath=$(dirname $(which xastir))

echo "Xastir path: $xastirpath"

if [ -d "/usr/share/xastir" ] ; then
    filecnt=$(ls -salt /usr/share/xastir/sounds | grep -c -i "wav")
    echo "xastir share dir exists, with $filecnt sound files"
else
    echo "xastir share dir does NOT exist"
fi

if [ -d "/usr/local/share/xastir" ] ; then
    filecnt=$(ls -salt /usr/local/share/xastir/sounds | grep -c -i "wav")
    echo "xastir local share dir exists, with $filecnt sound files"

else
    echo "xastir local share dir exists"
fi

