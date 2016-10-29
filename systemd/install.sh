#!/bin/bash
#
USER=gunn
userbindir=/home/$USER/bin
myname="`basename $0`"

AX25_FILES="ax25-downd  ax25-upd  ax25dev-parms"
BIN_FILES="ax25-start  ax25-status  ax25-stop"
LOGCFG_FILES="01-direwolf.conf  direwolf"
DIREWOLF_LOG_DIR="/var/log/direwolf"
SERVICE_FILES="ax25-mheardd.service  ax25dev.path direwolf.service ax25d.service ax25dev.service"
REQUIRED_FILES="direwolf mheardd mkiss kissparms kissattach"

# ===== function DiffFiles

function DiffFiles() {

echo "Check for required files ..."
EXITFLAG=false

for filename in `echo ${REQUIRED_FILES}` ; do
   type -P $prog_name &>/dev/null
   if [ $? -ne 0 ] ; then
      echo "$myname: Need to Install $prog_name program"
      EXITFLAG=true
   fi
done
if [ "$EXITFLAG" = "true" ] ; then
  exit 1
fi
echo "START comparing files ..."

for filename in `echo ${AX25_FILES}` ; do

# Check if file exists.
   if [ -f "/etc/ax25/$filename" ] ; then
      echo "Comparing $filename"
      diff ax25/$filename /etc/ax25/$filename
   else
      echo "file /etc/ax25/$filename DOES NOT EXIST"
   fi
done
for filename in `echo ${SERVICE_FILES}` ; do

# Check if file exists.
   if [ -f "/etc/systemd/system/$filename" ] ; then
      echo "Comparing $filename"
      diff -s sysd/$filename /etc/systemd/system/$filename
   else
      echo "file /etc/systemd/system/$filename DOES NOT EXIST"
   fi
done
for filename in `echo ${BIN_FILES}` ; do

# Check if file exists.
   if [ -f "$userbindir/$filename" ] ; then
      diff bin/$filename $userbindir/$filename
   else
      echo "file $userbindir/$filename DOES NOT EXIST"
   fi
done

# Check the 2 log config files

filename="01-direwolf.conf"
# Check if file exists.
   if [ -f "/etc/rsyslog.d/$filename" ] ; then
      diff logcfg/$filename /etc/rsyslog.d/$filename
   else
      echo "file /etc/rsyslog.d/$filename DOES NOT EXIST"
   fi

filename="direwolf"
# Check if file exists.
   if [  -f "/etc/logrotate.d/$filename" ] ; then
      diff logcfg/$filename /etc/logrotate.d/$filename
   else
      echo "file /etc/logrotate.d/$filename DOES NOT EXIST"
   fi

echo "FINISHED comparing files"

}

# ===== function CopyFiles

function CopyFiles() {

# make sure we're running as root
if (( `id -u` != 0 )); then
   echo "Sorry, must be root.  Exiting...";
   exit 1;
fi

echo "copy ax.25 files ..."
# check if /etc/ax25 or /usr/local/etc/ directories exist
if [ ! -d "/etc/ax25" ] && [ ! -L /etc/ax25 ] ; then
   if [ ! -d "/usr/local/etc/ax25" ] ; then
      echo "ax25 directory /usr/local/etc/ax25 DOES NOT exist, install ax25 first"
      exit
   else
      echo "Making symbolic link to /etc/ax25"
      ln -s /usr/local/etc/ax25 /etc/ax25
   fi
else
   echo " Found ax.25 link or directory"
fi
cp ax25/* /etc/ax25/

echo "copy systemd service files ..."
cp sysd/* /etc/systemd/system/

echo "copy log cfg files ..."

#-- creates /var/log/direwolf, if not exists
if [ ! -d "${DIRWOLF_LOG_DIR}" ] ; then
   echo "Create direwolf log directory: $DIREWOLF_LOG_DIR"
   mkdir -p "$DIREWOLF_LOG_DIR"
fi

cp logcfg/01-direwolf.conf /etc/rsyslog.d/
cp logcfg/direwolf /etc/logrotate.d/

echo "restart syslog"
service rsyslog restart

echo "test log rotate, view status before ..."

cat /var/lib/logrotate/status
logrotate -v -f /etc/logrotate.d/direwolf

echo "test log rotate, view status after ..."
cat /var/lib/logrotate/status


# Check if file exists.
if [ ! -d "$userbindir" ] ; then
   mkdir $userbindir
fi

cp bin/ax25-* $userbindir

echo
echo "FINISHED copying files"
}

# ==== main ====

#if [ -z "$1" ] ; then
#   echo "No args found just copy files"
#   CopyFiles
#   exit 0
#fi

# if there are any args on command line just diff files

if (( $# != 0 )) ; then
   DiffFiles
   exit 0
fi

# make sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root to install. Checking files"
   DiffFiles
   exit 0
fi

CopyFiles
systemctl enable ax25dev.path
systemctl enable direwolf.service

exit 0
