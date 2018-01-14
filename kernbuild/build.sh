#!/bin/bash
TOOLS_DIR=/home/gunn/tools/arm-bcm2708/arm-rpi-4.9.3-linux-gnueabihf/bin/arm-linux-gnueabihf-
#TOOLS_DIR=/home/gunn/projects/rpi/tools/arm-bcm2708/arm-rpi-4.9.3-linux-gnueabihf/bin/arm-linux-gnueabihf-
#TOOLS_DIR=/home/gunn/projects/rpi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin/arm-linux-gnueabihf-

echo "============================"
echo "Using TOOLS: $TOOLS_DIR"
echo "Build tools verion:"
$(${TOOLS_DIR}gcc -v) | grep -i "gcc version"

num_cores=$(nproc --all)
branch=$(git branch | grep \* | cut -d ' ' -f2)

echo "============================"
echo "BUILDING new config using branch: $branch"
KERNEL=kernel7
make -j$num_cores ARCH=arm CROSS_COMPILE=$TOOLS_DIR/arm-linux-gnueabihf- udr_defconfig
if [ $? -ne 0 ] ; then
   echo "Problem building new config"
   exit 1
fi

echo "============================"
echo "BUILDING zImage modules dtbs using $num_cores cores"
make -j$num_cores ARCH=arm CROSS_COMPILE=$TOOLS_DIR zImage modules dtbs
if [ $? -ne 0 ] ; then
   echo "Problem building zImage modules dtbs"
   exit 1
fi

echo "============================"
echo "INSTALLING modules locally"
make -j$num_cores ARCH=arm CROSS_COMPILE=$TOOLS_DIR INSTALL_MOD_PATH=.. modules_install
if [ $? -ne 0 ] ; then
   echo "Problem installing modules"
   exit 1
fi

echo "============================"
echo "COPY files to SD card"


exit 0