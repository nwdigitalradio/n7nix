#!/bin/bash

LOCAL_FILE=

filedir="/var/www/downloads"

# ===== function sum_it
function sum_it() {
    # ignore files that are symbolic links
    if [[ ! -L "$filename" ]]; then

        pushd $filedir > /dev/null

        filesize=$(stat -c%s "$filename")
        filedate=$(date -r "$filename")
        {
         echo "File size in bytes: $filesize $filedate $(basename $filename)"
         # ls -l "$filedir/$filename"

         echo -n "md5sum: "
         md5sum $(basename $filename)

         echo -n "sha256sum: "
         sha256sum $(basename $filename)
         popd > /dev/null

         echo
         } | (tee -a $filedir/checksum.txt)
    fi
}


# ===== main

# Add an argument to command line if testing on local machine
if [[ $# -gt 0 ]] ; then
    echo "Using local file system: $(pwd)"
    LOCAL_FILE=1
#    filedir="/home/flash_image"
    filedir="$(pwd)"
    filename="nwdr23.img.xz"
else
    echo "Using web downloaded file"
fi

if [ -e $filedir/checksum.txt ] ; then
    rm $filedir/checksum.txt
fi

if [ -z $LOCAL_FILE ] ; then
    for filename in $filedir/*.xz ; do
        sum_it
    done
else
    sum_it
fi
