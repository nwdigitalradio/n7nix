#!/bin/bash
#
# Install Updates for the Linux RMS Gateway
#
# Parts taken from RMS-Upgrade-181 script Updated 10/30/2014
# (https://groups.yahoo.com/neo/groups/LinuxRMS/files)
# by C Schuman, K4GBB k4gbb1gmail.com
#
#
#
# Uncomment this statement for debug echos
DEBUG=1

# Color Codes
Reset='\e[0m'
Red='\e[31m'
Green='\e[32m'
Yellow='\e[33m'
Blue='\e[34m'
White='\e[37m'
BluW='\e[37;44m'

PKG_REQUIRE="xutils-dev libxml2 libxml2-dev python-requests"
PKG_LIST=
SRC_DIR="/usr/local/src/ax25/rmsgw"

Version="rmsgw-2.4.0-181"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed")
}

# ===== main
echo -e "${BluW}\n \t  Update Linux RMS Gate \n${Yellow}\t     $Version  \t \n \t \n${White}  Script provided by Charles S. Schuman ( K4GBB )  \n${Red}               k4gbb1@gmail.com \n${Reset}"


# check if packages are installed
dbgecho "Check packages: $PKG_REQUIRE"
needs_pkg=false

for pkg_name in `echo ${PKG_REQUIRE}` ; do

   is_pkg_installed $pkg_name
   if [ $? -eq 0 ] ; then
      echo "$myname: Need to Install $pkg_name program"
      apt-get -qy install $pkg_name
   fi
done

if [ "$needs_pkg" = "true" ] ; then
   echo -e "${BluW}\t Installing Support libraries \t${Reset}"

   apt-get install -y -q $APT_GET_PRGS
   if [ "$?" -ne 0 ] ; then
      echo "Support library install failed. Please try this command manually:"
      echo "apt-get -y $PKG_LIST"
      exit 1
   fi
fi

# source directory exist
if [ ! -d $SRC_DIR ] ; then
   mkdir -p $SRC_DIR
   if [ "$?" -ne 0 ] ; then
      echo "Problems creating source directory: $SRC_DIR"
   fi
fi

cd $SRC_DIR

# Determine if any rmsgw tgz files have been downloaded
ls rmsgw-*.tgz 2>/dev/null
if [ $? -ne 0 ] ; then
   echo -e "${BluW}\t Downloading $Version Source file \t${Reset}"

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
fi

TGZ_FILELIST="$(ls rmsgw-*.tgz |tr '\n' ' ')"
ls rmsgw-*.tgz
dbgecho
dbgecho "Found these tgz files $TGZ_FILELIST"
dbgecho

for filename in *.tgz ; do
   rms_ver="$(echo ${filename#r*-} | cut -d '.' -f1,2,3)"
   echo "$filename version: $rms_ver"
done

dbgecho "Early exit"
exit


tar xf $Version.tgz
if [ $? -ne 0 ] ; then
 echo -e "${BluW}${Red}\t $Version File not available \t${Reset}"
 exit 1
fi

echo -e "${BluW}\t Compiling RMS Source file \t${Reset}"
cd /usr/local/src/ax25/$Version
make > RMS.txt

if [ $? -ne 0 ]
   then
 echo -e "${BluW}$Red} \tCompile error${White} - check RMS.txt File \t${Reset}"
 exit 1
   else
 rm RMS.txt
fi
make install
# rm /etc/rmsgw/stat/.*


echo -e "${BluW}RMS Gate updated \t${Reset}"

     date >> /root/Changes
     echo "        RMS Gate Upgraded - $Version" >> /root/Changes
     nano /root/Changes
     exit 0

# (End of Script)
