#!/bin/bash
#
# Backup all new config files from a UDRC install
#
version="1.0"
scriptname="`basename $0`"
USER=$(whoami)

filecount=0
notexistcount=0
diff_filecount=0

#list of config directories
configdirs="etc rmsgw wpa_supplicant iptables postfix logrotate.d ax25 systemd/system"

# List of config files
etc_configfiles="hosts hostname mailname direwolf.conf aliases"
postfix_configfiles="main.cf master.cf transport"
dovecot_configfiles="dovecot.conf conf.d/10-mail.conf conf.d/10-master.conf conf.d/10-auth.conf conf.d/10-ssl.conf"
rmsgw_configfiles="channels.xml gateway.conf sysop.xml banner"
wpa_configfiles="wpa_supplicant.conf"
localetc_configfiles="wl2k.conf"
iptables_configfiles="rules.ipv4.ax25 rules.v4 rules.v6"
logrotate_configfiles="rms direwolf"
ax25_configfiles="ax25d.conf axports ax25dev-parms"
systemd_files="ax25dev.path ax25dev.service direwolf.service pluweb.service"
bin_files="set-udrc-both.sh"
xastir_files="*"

TMPDIR=/home/$USER/tmp
BUPDIR="$TMPDIR/cfgbup"

# ===== function usage
function usage() {
   echo "$scriptname version: $version"
   echo "Usage: $scriptname [-d][-h]" >&2
   echo "   -d no arg, diff cfg files."
   echo "   -c no arg, copy/backup cfg files."
   echo "   -r no arg, restore cfg files."
   echo "   -h no arg, display this message"
   echo
}

# ===== function diff_files
# 1st arg, file list
# 2nd arg, source directory

function diff_files() {
configfilelist="$(echo $1)"
configdir="$2"
destdir=${2#"/"}
destdir="$BUPDIR/$destdir"

if [ ! -d "$destdir" ] ; then
   echo
   echo "Directory: $destdir does not exist"
   echo
   return;
fi

for filename in `echo ${configfilelist}` ; do
      destfname="$destdir$filename"
      if [ ! -e "$destfname" ] ; then
         echo
         echo "File: $destfname does not exist"
         echo
         (( ++notexistcount ))
         continue;
      fi

      fname="$configdir$filename"
      if [ ! -e "$fname" ] ; then
         echo
         echo "File: $fname does not exist "
         echo
         (( ++notexistcount ))
         continue;
      else
         diffcnt=$(diff -y --suppress-common-lines $fname $destfname | wc -l)
         echo "Diff file: $fname with: $destfname, $diffcnt lines differ."
         (( ++filecount ))
         if (( diffcnt > 0 )) ; then
            (( ++diff_filecount ))
         fi
      fi
done
}

# ===== function copy_files
# 1st arg, file list
# 2nd arg, source directory

function copy_files() {

configfilelist="$(echo $1)"
configdir="$2"
destdir=${2#"/"}
destdir="$BUPDIR/$destdir"

# echo "debug: file list: ${configfilelist}"
# echo "debug: cfg dir: $configdir"
# echo "debug: dest dir: $destdir"

if [ ! -d "$destdir" ] ; then
   mkdir -p "$destdir"
   echo "Created dir $destdir"
fi

for filename in `echo ${configfilelist}` ; do
      destfname="$destdir$filename"
      dstmsg=""
      if [ -e "$destfname" ] ; then
         dstmsg=$(echo ", File $destfname already exists")
      fi
      fname="$configdir$filename"
      if [ -e "$fname" ] ; then
         echo "==== Source file: $fname$dstmsg"
         cp "$fname" "$destfname"
         (( ++filecount ))
      else
         echo
         echo "file: $fname does not exist"
         echo
         (( ++notexistcount ))

      fi
done
}

# ===== main

# Running as root?
if [[ $EUID == 0 ]] ; then
   echo
   echo "You are running this script as root ... don't do that."
   exit 1
fi

# Setup tmp directory
if [ ! -d "$TMPDIR" ] ; then
  mkdir "$TMPDIR"
fi

# if backup directory exists rename it
if [ -d "$BUPDIR" ] ; then
   echo "A backup dir already exists, renaming to $BUPDIR.$(date "+%Y%m%d_%H%M")"
   mv $BUPDIR $BUPDIR.$(date "+%Y%m%d_%H%M")
   mkdir -p $BUPDIR/etc/dovecot/conf.d
fi

# Get all installed packages
install_curfname=$BUPDIR/installed_cur.txt
install_lastfname=$BUPDIR/installed_last.txt
if [ -e "$install_curfname" ] ; then
   mv $install_curfname $install_lastfname
   dpkg -l|awk '/^ii/{ print $2 }'|grep -v -e ^lib -e -dev -e $(uname -r) > $install_curfname
   echo "New packages installed: "
   diff -b $install_curfname $install_lastfname
else
   dpkg -l|awk '/^ii/{ print $2 }'|grep -v -e ^lib -e -dev -e $(uname -r) > $install_curfname
fi


# Default to copying files
bupcmd="copy_files"
bupfunction="Copy"

# Command line args are passed with a dash & single letter
#  See usage function
while [[ $# -gt 0 ]] ; do
key="$1"

case $key in
   -c)
      bupcmd="copy_files"
      bupfunction="Copy"
   ;;
   -d)
      bupcmd="diff_files"
      bupfunction="Diff"
   ;;
   -r)
      bupcmd="restore_files"
      bupfunction="Restore"
      echo "debug: Would have done a restore"
      exit
   ;;
   -h|--help|?)
      usage
      exit 0
   ;;
   *)
      # unknown option
      echo "Unknow option: $key"
      usage
      exit 1
   ;;
esac
shift # past argument or value
done


$bupcmd "$etc_configfiles" "/etc/"
$bupcmd "$postfix_configfiles" "/etc/postfix/"
$bupcmd "$dovecot_configfiles" "/etc/dovecot/"
$bupcmd "$rmsgw_configfiles" "/etc/rmsgw/"
$bupcmd "$wpa_configfiles" "/etc/wpa_supplicant/"
$bupcmd "$localetc_configfiles" "/usr/local/etc/"
$bupcmd "$iptables_configfiles" "/etc/iptables/"
$bupcmd "$logrotate_configfiles" "/etc/logrotate.d/"
$bupcmd "$ax25_configfiles" "/etc/ax25/"
$bupcmd "$systemd_files" "/etc/systemd/system/"
$bupcmd "$bin_files" "/home/$USER/bin/"
# treat xastir config directory differently
if [ "$bupfunction" = "Copy" ] ; then
   echo "debug: using rsync on xastir directory for backup"
   rsync -av /home/$USER/.xastir $BUPDIR
elif [ "$bupfunction" = "Restore" ] ; then
   echo "debug: using rsync on xastir directory for restore"
   rsync -av "$BUPDIR/xastir/*" /home/$USER/.xastir/
else
# recursive diff
   echo "debug: using recursive diff on xastir directory"
   diff -bwBr --brief $BUPDIR/xastir/ /home/$USER/.xastir/
fi

echo "$bupfunction finished for $filecount files."
if (( notexistcount > 0 )) ; then
   echo "Files not found $notexistcount"
fi

if [ "$bupcmd" = "diff_files" ] ; then
   echo "Number of different files: $diff_filecount"
fi