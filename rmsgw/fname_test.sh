#!/bin/bash
DEBUG="1"
user=$(whoami)

# Color code
BluW='\e[37;44m'

# SRCDIR="/usr/local/src/ax25/rmsgw"
SRCDIR="/home/$user/tmp/rmsgw"
EXTEN="bz2"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

echo
echo "=== setup test dir: $SRCDIR"
if [ ! -d $SRCDIR ] ; then
   mkdir -p $SRCDIR
echo
   echo "Test dir already exists"
fi

echo "=== Check if rmsgw compressed file already exists"
cd $SRCDIR
# EXTEN="tgz"
EXTEN="bz2"
# Determine if any rmsgw compressed files have been downloaded
ls rmsgw-*.$EXTEN 2>/dev/null
if [ $? -ne 0 ] ; then
   echo -e "${BluW}\t Downloading RMS Gateway Source file \t${Reset}"

   # wget -qt 3 http://k4gbb.no-ip.info/docs/scripts/$Version.tgz

   # Note: the following  didn't work
   #       Problematic to download a file from yahoo groups,
   # wget --no-check-certificate -t 3 https://groups.yahoo.com/neo/groups/LinuxRMS/files/Software/*.tgz

   wget -r -l1 -H -t1 -nd -N -np -qt 3 -A "rmsgw*.$EXTEN" http://k4gbb.no-ip.info/docs/scripts/
   if [ $? -ne 0 ] ; then
      echo "Problems downloading file,"
      echo "  go to https://groups.yahoo.com/neo/groups/LinuxRMS/files/Software"
      echo  "  and download from a browser, run this script again."
      exit 1
   fi
else
   # Get here if some $EXTEN files were found
   TGZ_FILELIST="$(ls rmsgw-*.$EXTEN |tr '\n' ' ')"

   echo "Already have rmsgw install file(s): $TGZ_FILELIST"
   echo "To check for a new version move .$EXTEN file(s) out of this directory: $SRCDIR"
fi

#filename=$(basename "$fullfile")
# extension="${filename##*.}"
# filename="${filename%.*}"

# Alternatively, you can focus on the last '/'
# of the path instead of the '.' which should work even if you have
# unpredictable file extensions:
#
# filename="${fullfile##*/}"

echo "=== list compressed rmsgw file:"

ls $SRCDIR/rmsgw-*.$EXTEN
echo
echo "Display version of compressed file:"
# Lists all .$EXTEN files in directory
# Last file listed should have lastest version number
for fullname in $SRCDIR/*.$EXTEN ; do
   filename=$(basename "$fullname")
   rms_ver="$(echo ${filename#r*-} | cut -d '.' -f1,2,3,4)"
   echo "$filename   version: $rms_ver"
done

dirname=$(echo ${fullname%$filename})
dbgecho "Untarring this version: $rms_ver of this file: $filename in this dir: $dirname"


#tar xf $filename
#if [ $? -ne 0 ] ; then
#   echo -e "${BluW}${Red}\t $filename File not available \t${Reset}"
#    exit 1
#fi

num_cores=$(nproc --all)
echo -e "${BluW}\tCompiling RMS Source file using $num_cores cores\t${Reset}"





