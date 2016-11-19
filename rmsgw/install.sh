#!/bin/bash
#
# Install Updates for the Linux RMS Gateway
#
# Parts taken from RMS-Upgrade-181 script Updated 10/30/2014
# (https://groups.yahoo.com/neo/groups/LinuxRMS/files)
# by C Schuman, K4GBB k4gbb1gmail.com
#
# Uncomment this statement for debug echos
DEBUG=1

myname="`basename $0`"

# Color Codes
Reset='\e[0m'
Red='\e[31m'
Green='\e[32m'
Yellow='\e[33m'
Blue='\e[34m'
White='\e[37m'
BluW='\e[37;44m'

PKG_REQUIRE="xutils-dev libxml2 libxml2-dev python-requests"
SRC_DIR="/usr/local/src/ax25/rmsgw"
ROOTFILE_NAME="rmsgw-"
RMS_BUILD_FILE="rmsbuild.txt"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed")
}

# ===== main

# echo -e "${BluW}\n \t  Update Linux RMS Gate \n${White}  Script
# provided by Charles S. Schuman ( K4GBB )  \n${Red}               k4gbb1@gmail.com \n${Reset}"
echo -e "${BluW}\n \t  Install Linux RMS Gate \n${White}  Parts of this Script provided by Charles S. Schuman ( K4GBB )  \n${Reset}"

# make sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root"
   exit 1
fi


# check if packages are installed
dbgecho "Check packages: $PKG_REQUIRE"
needs_pkg=false

for pkg_name in `echo ${PKG_REQUIRE}` ; do

   is_pkg_installed $pkg_name
   if [ $? -eq 0 ] ; then
      echo "$myname: Will Install $pkg_name program"
      needs_pkg=true
      break
   fi
done

if [ "$needs_pkg" = "true" ] ; then
   echo -e "${BluW}\t Installing Support libraries \t${Reset}"

   apt-get install -y -q $PKG_REQUIRE
   if [ "$?" -ne 0 ] ; then
      echo "Support library install failed. Please try this command manually:"
      echo "apt-get -y $PKG_REQUIRE"
      exit 1
   fi
fi

echo "All required packages installed."

# Does source directory exist?
if [ ! -d $SRC_DIR ] ; then
   mkdir -p $SRC_DIR
   if [ "$?" -ne 0 ] ; then
      echo "Problems creating source directory: $SRC_DIR"
      exit 1
   fi
fi

cd $SRC_DIR

# Determine if any rmsgw tgz files have been downloaded
ls rmsgw-*.tgz 2>/dev/null
if [ $? -ne 0 ] ; then
   echo -e "${BluW}\t Downloading RMS Gateway Source file \t${Reset}"

   # wget -qt 3 http://k4gbb.no-ip.info/docs/scripts/$Version.tgz

   # Note: the following  didn't work
   #       Problematic to download a file from yahoo groups,
   # wget --no-check-certificate -t 3 https://groups.yahoo.com/neo/groups/LinuxRMS/files/Software/*.tgz

   wget -r -l1 -H -t1 -nd -N -np -qt 3 -A ".tgz" http://k4gbb.no-ip.info/docs/scripts/
   if [ $? -ne 0 ] ; then
      echo "Problems downloading file,"
      echo "  go to https://groups.yahoo.com/neo/groups/LinuxRMS/files/Software"
      echo  "  and download from a browser, run this script again."
      exit 1
   fi
else
   # Get here if some tgz files were found
   TGZ_FILELIST="$(ls rmsgw-*.tgz |tr '\n' ' ')"

   echo "Already have rmsgw install file(s): $TGZ_FILELIST"
   echo "To check for a new version move .tgz file(s) out of this directory"
fi

# Lists all .tgz files in directory
# Last file listed should have lastest version number
for filename in *.tgz ; do
   rms_ver="$(echo ${filename#r*-} | cut -d '.' -f1,2,3)"
#   echo "$filename version: $rms_ver"
done

dbgecho "Untarring this installation file: $filename, version: $rms_ver"

tar xf $filename
if [ $? -ne 0 ] ; then
 echo -e "${BluW}${Red}\t $filename File not available \t${Reset}"
 exit 1
fi

echo -e "${BluW}\tCompiling RMS Source file \t${Reset}"

cd $SRC_DIR/$ROOTFILE_NAME$rms_ver

# Redirect stderr to stdout
make > $RMS_BUILD_FILE 2>&1
if [ $? -ne 0 ] ; then
   echo -e "${BluW}$Red} \tCompile error${White} - check $RMS_BUILD_FILE File \t${Reset}"
   exit 1
fi

if [[ $EUID != 0 ]] ; then
   echo "Must be root to install."
   echo "Become root, then 'make install'"
   exit 1
fi

echo -e "${BluW}\t Installing RMS Gateway\t${Reset}"
make install
if [ $? -ne 0 ] ; then
  echo "Error during install."
  exit 1
fi
# rm /etc/rmsgw/stat/.*

UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
echo "$(date "+%Y %m %d %T %Z"): RMS Gateway updated" >> $UDR_INSTALL_LOGFILE
echo -e "${BluW}RMS Gateway updated \t${Reset}"

# (End of Script)
