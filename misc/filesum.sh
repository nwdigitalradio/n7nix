#!/bin/bash

filedir="/var/www/downloads"
# filedir="/home/flash_image"

if [ -e $filedir/checksum.txt ] ; then
    rm $filedir/checksum.txt
fi

for filename in $filedir/*.xz ; do
    # ignore files that are symbolic links
    if [[ ! -L "$filename" ]]; then
        filesize=$(stat -c%s "$filename")
        filedate=$(date -r "$filename")
        {
         echo "File size in bytes: $filesize $filedate $(basename $filename)"
         # ls -l "$filedir/$filename"
         pushd $filedir > /dev/null
         echo -n "md5sum: "
         md5sum $(basename $filename)
         echo -n "sha256sum: "
         sha256sum $(basename $filename)
         popd > /dev/null
         echo
         } | (tee -a $filedir/checksum.txt)
    fi
done
