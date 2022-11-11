#!/bin/bash
#
# Download mainline Ubuntu kernels from Ubuntu ppa (11112022)
#  https://kernel.ubuntu.com/~kernel-ppa/mainline/v$KERN_VER/
#
#  amd64/linux-headers-5.19.11-051911-generic_5.19.11-051911.202209231341_amd64.deb
#  amd64/linux-headers-5.19.11-051911_5.19.11-051911.202209231341_all.deb
#  amd64/linux-image-unsigned-5.19.11-051911-generic_5.19.11-051911.202209231341_amd64.deb
#  amd64/linux-modules-5.19.11-051911-generic_5.19.11-051911.202209231341_amd64.deb


KERN_VER="5.19.11"
PPA_URL="https://kernel.ubuntu.com/~kernel-ppa/mainline/v$KERN_VER"

# Download headers, image & modules
wget $PPA_URL/amd64/linux-headers-5.19.11-051911-generic_5.19.11-051911.202209231341_amd64.deb
wget $PPA_URL/amd64/linux-image-unsigned-5.19.11-051911-generic_5.19.11-051911.202209231341_amd64.deb
wget $PPA_URL/amd64/linux-modules-5.19.11-051911-generic_5.19.11-051911.202209231341_amd64.deb

# Install downloaded packages
# sudo dpkg -i amd64/linux-headers-5.19.11-051911-generic_5.19.11-051911.202209231341_amd64.deb
# sudo dpkg -i linux-image-unsigned-5.19.11-051911-generic_5.19.11-051911.202209231341_amd64.deb
# sudo dpkg -i linux-modules-5.19.11-051911-generic_5.19.11-051911.202209231341_amd64.deb

echo "Finished installing kernel version: $KERN_VER
