#!/bin/bash
#
# When installing with dpkg must maintain order of modules, image then
# headers otherwise install will error out with dependency errors.
#
# Download mainline Ubuntu kernels from Ubuntu ppa (11112022)
#  https://kernel.ubuntu.com/~kernel-ppa/mainline/v$KERN_VER/
#
#  KERN_VER="5.19.11" 2022-09-23 14:39
#  kernver="5.19.11-051911-generic_5.19.11-051911.202209231341"
#
## Note 2 different header files
#  amd64/linux-headers-5.19.11-051911-generic_5.19.11-051911.202209231341_amd64.deb
#  amd64/linux-headers-5.19.11-051911_5.19.11-051911.202209231341_all.deb
#  amd64/linux-image-unsigned-5.19.11-051911-generic_5.19.11-051911.202209231341_amd64.deb
#  amd64/linux-modules-5.19.11-051911-generic_5.19.11-051911.202209231341_amd64.deb
#
#  KERN_VER="5.19.17" 2022-10-24 14:25
#  kernver="5.19.17-051917-generic_5.19.17-051917.202210240939"
#
#  amd64/linux-headers-5.19.17-051917-generic_5.19.17-051917.202210240939_amd64.deb
#  amd64/linux-headers-5.19.17-051917_5.19.17-051917.202210240939_all.deb
#  amd64/linux-image-unsigned-5.19.17-051917-generic_5.19.17-051917.202210240939_amd64.deb
#  amd64/linux-modules-5.19.17-051917-generic_5.19.17-051917.202210240939_amd64.deb
#
# KERN_VER="6.0.8" 22-11-10
# kernver="6.0.8-060008-generic_6.0.8-060008.202211101901"
# amd64/linux-headers-6.0.8-060008-generic_6.0.8-060008.202211101901_amd64.deb
# amd64/linux-headers-6.0.8-060008_6.0.8-060008.202211101901_all.deb
# amd64/linux-image-unsigned-6.0.8-060008-generic_6.0.8-060008.202211101901_amd64.deb
# amd64/linux-modules-6.0.8-060008-generic_6.0.8-060008.202211101901_amd64.deb

#KERN_VER="5.19.17"
#kernver="5.19.17-051917-generic_5.19.17-051917.202210240939"
#kernver_h="5.19.17-051917_5.19.17-051917.202210240939"

KERN_VER="6.0.8"
kernver="6.0.8-060008-generic_6.0.8-060008.202211101901"
kernver_h="6.0.8-060008_6.0.8-060008.202211101901"

PPA_URL="https://kernel.ubuntu.com/~kernel-ppa/mainline/v$KERN_VER"

echo "User: $USER"
download_dir="/home/$USER/Downloads"

if [ ! -d "$download_dir" ] ; then
    echo "Download Directory: $download_dir does not exist"
    exit 1
fi

echo "Downloading to directory $download_dir"
cd $download_dir

# Download headers, image & modules

if [ ! -e "linux-headers-${kernver}_amd64.deb" ] ; then

    wget $PPA_URL/amd64/linux-headers-${kernver}_amd64.deb
    if [ "$?" -ne 0 ] ; then
        echo "headers download FAILED: $PPA_URL/amd64/linux-headers-${kernver}_amd64.deb"
	exit 1
    fi
else
    echo "file already exists: linux-headers-${kernver}_amd64.deb"
fi

## Note: 2 different header files
#amd64/linux-headers-5.19.17-051917-generic_5.19.17-051917.202210240939_amd64.deb
#amd64/linux-headers-5.19.17-051917_5.19.17-051917.202210240939_all.deb

if [ ! -e "linux-headers-${kernver_h}_all.deb" ] ; then

    wget $PPA_URL/amd64/linux-headers-${kernver_h}_all.deb
    if [ "$?" -ne 0 ] ; then
        echo "headers download FAILED: $PPA_URL/amd64/linux-headers-${kernver_h}_all.deb"
	exit 1
    fi
else
    echo "file already exists: linux-headers-${kernver_h}_all.deb"
fi



if [ ! -e "linux-image-unsigned-${kernver}_amd64.deb" ] ; then

    wget $PPA_URL/amd64/linux-image-unsigned-${kernver}_amd64.deb
    if [ "$?" -ne 0 ] ; then
        echo "Linux image download FAILED: $PPA_URL/amd64/linux-image-unsigned-${kernver}_amd64.deb"
	exit 1
    fi
else
    echo "file already exists: linux-image-unsigned-${kernver}_amd64.deb"
fi

if [ ! -e linux-modules-${kernver}_amd64.deb ] ; then
    wget $PPA_URL/amd64/linux-modules-${kernver}_amd64.deb
    if [ "$?" -ne 0 ] ; then
        echo "Linux Modules download FAILED: $PPA_URL/amd64/linux-modules-${kernver}_amd64.deb"
	exit 1
    fi
else
    echo "file already exists: linux-modules-${kernver}_amd64.deb"
fi

# Install downloaded packages
echo
echo "Installing modules"
sudo dpkg -i linux-modules-${kernver}_amd64.deb
if [ "$?" -ne 0 ] ; then
    echo "modules install FAILED"
fi

echo
echo "Installing kernel image"
sudo dpkg -i linux-image-unsigned-${kernver}_amd64.deb
if [ "$?" -ne 0 ] ; then
    echo "kernel image install FAILED"
fi

echo
echo "Installing headers"
sudo dpkg -i linux-headers-${kernver_h}_all.deb
if [ "$?" -ne 0 ] ; then
    echo "headers install FAILED"
fi

echo
echo "Installing generic headers"
sudo dpkg -i linux-headers-${kernver}_amd64.deb
if [ "$?" -ne 0 ] ; then
    echo "generic headers install FAILED"
fi

echo
echo "Finished installing kernel version: $KERN_VER"
