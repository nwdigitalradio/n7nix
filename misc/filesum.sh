#!/bin/bash

filelist=" nwdr20.2.img.xz nwdr21.img.xz"
filedir="/home/flash_image"

if [ -e $filedir/checksum.txt ] ; then
    rm $filedir/checksum.txt
fi

for filename in $filedir/*.xz ; do
    filesize=$(stat -c%s "$filename")
    filedate=$(date -r "$filename")
    {
    echo "File size in bytes: $filesize $filedate $(basename $filename)"
#    ls -l "$filedir/$filename"
    pushd $filedir > /dev/null
    echo -n "md5sum: "
    md5sum $(basename $filename)
    echo -n "sha256sum: "
    sha256sum $(basename $filename)
    popd > /dev/null
    echo
    } | (tee -a $filedir/checksum.txt)
done