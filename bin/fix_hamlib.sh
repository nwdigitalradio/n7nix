#!/bin/bash
#
# If hamlib is built from source make sure there are no old versions in
# path

echo
echo "== hamlib check"

arm_hamlib_cnt=0
local_hamlib_cnt=0

# Check for older versions of hamlib
hamlib_dir="/usr/lib/arm-linux-gnueabihf"
if [ -d "$hamlib_dir" ] && [ -e $hamlib_dir/libhamlib.so.4 ] ; then
    libcnt=$(ls -1 $hamlib_dir/libhamlib* | wc -l)
    if ((libcnt > 0 )) ; then
        arm_hamlib_cnt=$libcnt
        echo "hamlib: Found $arm_hamlib_cnt hamlib files in $hamlib_dir"
        ls -alt $hamlib_dir/libhamlib*
    else
        echo "hamlib: NO hamlib files found in $hamlib_dir"
    fi
else
    echo "hamlib directory: $hamlib_dir files do NOT exist"
fi

# Check for newer versions of hamlib
hamlib_dir="/usr/local/lib"
if [ -d "$hamlib_dir" ] && [ -e "$hamlib_dir/libhamlib.so.4" ] ; then
    libcnt=$(ls -1 $hamlib_dir/libhamlib* | wc -l)
    if ((libcnt > 0 )) ; then
        local_hamlib_cnt=$libcnt
        echo "hamlib: Found $local_hamlib_cnt hamlib files in $hamlib_dir"
        ls -alt $hamlib_dir/libhamlib*
    else
        echo "hamlib: NO hamlib files found in $hamlib_dir"
    fi
else
    echo "hamlib directory: $hamlib_dir files do NOT exist"
fi

echo
hamlib_dir="/usr/lib/arm-linux-gnueabihf"
if ((arm_hamlib_cnt > 0)) && ((local_hamlib_cnt > 0)) ; then
    echo "Removing conflicting hamlib files from: $hamlib_dir"
    sudo rm $hamlib_dir/libhamlib*
else
    echo "No hamlib files removed"
fi
