#!/bin/bash
#
# Verify email configuration for winlink using postfix
#
scriptname="`basename $0`"
USER=$(whoami)
wl2ktransport="/usr/local/bin/wl2ktelnet -s"

#CALLSIGN="N7NIX"
#REALNAME="Basil Gunn"
CALLSIGN="KD5MKV"
REALNAME="Steve Rogers"

sendto_wl=n7nix@winlink.org
sendto_local="$USER@localhost"
ccto=
SPOOL_FILE="/var/mail/$USER"

GROUP="mail"
TMPDIR=/home/$USER/tmp

WAIT_TIME=12
PLU_VAR_DIR="/usr/local/var/wl2k"
outboxdir="$PLU_VAR_DIR/outbox"
INDEX_FILENAME="$TMPDIR/indexfile.txt"
MSG_FILENAME="$TMPDIR/testmsg.txt"

MUTT="/usr/bin/mutt"
# Set boolean for this script generated email body
bgenbody="false"
outboxfile_cnt=0

# ===== function chk_perm
# Check permissions of the winlink outbox directory

function chk_perm() {
# set permissions for /usr/local/var/wl2k directory
# Check user & group of outbox directory
#
{
echo "=== test owner & group id of outbox directory"
if [ $(stat -c "%U" $PLU_VAR_DIR) != "$USER" ]  || [ $(stat -c "%G" $PLU_VAR_DIR) != "$GROUP" ] ; then
   echo "Outbox dir has wrong permissions: $(stat -c "%U" $PLU_VAR_DIR):$(stat -c "%G" $PLU_VAR_DIR)"
   sudo chown -R $USER:$GROUP $PLU_VAR_DIR
   echo "New permissions: $(stat -c "%U" $PLU_VAR_DIR):$(stat -c "%G" $PLU_VAR_DIR)"
else
   echo "Outbox dir permissions OK: $(stat -c "%U" $PLU_VAR_DIR):$(stat -c "%G" $PLU_VAR_DIR)"
fi

filecount=$(ls -1 ${PLU_VAR_DIR}/outbox | wc -l)
if [ -z $filecount ] ; then
  filecount=0
fi
} >> $email_logfile
}

# ===== function count_files_ob
# count number of files in outbox
count_files_ob() {
{
# dump any files in winlink outbox to log file
if (( $filecount > 0 )) ; then
   echo " Files in outbox: $filecount for callsign: $CALLSIGN"
   outboxfiles=$(ls -1 ${PLU_VAR_DIR}/outbox/*_$CALLSIGN)
   if [ ! -z "$outboxfiles" ] ; then
      outboxfile_cnt="$outboxfiles"
      for filename in `echo ${outboxfiles}` ; do
         echo "==== email: $filename"
         cat $filename
         echo
      done
   else
      echo "No files for $CALLSIGN found"
      ls -1 ${PLU_VAR_DIR}/outbox/
      outboxfile_cnt=0
   fi
else
   echo " No files in outbox"
   outboxfile_cnt=0
fi
} >> $email_logfile
}

# ===== function send_email
# Needs argument for who to send to
function send_email() {

sendto="$1"

{
# if index file doesn't exist create it & set contents to a zero
if [ ! -e "$INDEX_FILENAME" ] ; then
  echo "INFO: file $INDEX_FILENAME DOES NOT exist"
  echo "0" > $INDEX_FILENAME
fi

# Load the test index
testindex=$(cat $INDEX_FILENAME)

# Look for a file to make email body
#   - if it doesn't exist make something up
if [ ! -e "$MSG_FILENAME" ] ;then
{
  echo "Sent on: $(date "+%m/%d %T %Z")"
  echo "/$(whoami)"
  bgenbody="true"

} > $MSG_FILENAME
fi

# get the test file size
FILESIZE=$(stat -c%s "$MSG_FILENAME")
echo "Test $(date "+%m/%d/%y") #$testindex, File size of $MSG_FILENAME = $FILESIZE"

subject="//WL2K $(hostname) plu $(date "+%m/%d/%y"), size: $FILESIZE, #$testindex"

echo "$subject"
echo "plu outbox owner: $(stat -c '%U' /usr/local/var/wl2k) $(stat -c '%G' /usr/local/var/wl2k/outbox)"

# Test if Cc: is used
if [[ -z "$ccto" ]] ; then
   $MUTT -s "$subject" $sendto < $MSG_FILENAME
else
   $MUTT -s "$subject" -c $ccto $sendto < $MSG_FILENAME
fi

# increment the index
let testindex=$testindex+1

# Write new index back out to index file
echo "$testindex" > $INDEX_FILENAME

# If this script generated the mail body delete the temporary file.
if  [ "$bgenbody" = "true" ] ; then
   rm "$MSG_FILENAME"
fi
echo "email generation for $sendto finished."
} >> $email_logfile
}

# ===== function
get_last_maillog() {
   filename="/var/log/mail.log"
   last_ml=$(tail -n1 $filename)
   last_ln=$(wc -l $filename | cut -d ' ' -f1)
   echo "last line mail log[$last_ln]: $last_ml" >> $email_logfile
}


# ===== function get_mail_log
dump_maillog() {
   filename="/var/log/mail.log"
   {
   filesize=$(stat --printf="%s" $filename)
   if (( filesize == 0 )) ; then
      echo "No entries in $filename trying $filename.1"
      filename=$(echo "$filename.1")
      filesize=$(stat --printf="%s" $filename)
   fi

   echo "dump_maillog: size of file: $filename: $filesize"
   echo "debug: using start line: $last_ml"
   echo "debug: using from line number: $last_ln to last line: $(wc -l $filename | cut -d ' ' -f1)"

   echo "mail.log start"

   # wait for log file to populate
   sleep 2
   sed -n $last_ln,\$p  $filename

   echo "mail.log end"
   echo
   } >> $email_logfile
}

# ===== function dump_files
dump_files() {
filelist="/etc/hostname /etc/hosts /etc/postfix/main.cf /usr/local/etc/wl2k.conf"
{
   for fname in `echo ${filelist}` ; do

      if [ -e "$fname" ] ; then
         echo "==== file: $fname"
         cat $fname
         echo
      else
         echo "file: $fname does not exist"
      fi
   done
} >> $email_logfile
}

# ===== function chk_spool_file
chk_spool_file() {
{
   if [ ! -e "$SPOOL_FILE" ] ; then
      echo "Spool file $SPOOL_FILE" does not exist!
      sudo touch $SPOOL_FILE
      sudo chown $USER:mail $SPOOL_FILE
   else
      echo "Spool file $SPOOL_FILE  does exist"
   fi
   ls -al /var/mail
} >> $email_logfile
}

# ===== function config_mutt
config_mutt() {

# Set directory where mail will stored
#  Must match folder & spoolfile directories in .muttrc file below

MAILDIR="/home/$USER/Mail"
if [ ! -d $MAILDIR ] ; then
   # Setup up mutt Maildir
   mkdir -p $MAILDIR/{,cur,tmp,new}
   mkdir -p $MAILDIR/inbox/{,cur,tmp,new}
   mkdir -p $MAILDIR/sent/{,cur,tmp,new}
   mkdir -p $MAILDIR/drafts/{,cur,tmp,new}
   mkdir -p $MAILDIR/trash/{,cur,tmp,new}
   mkdir -p $MAILDIR/attachments/{,cur,tmp,new}
   chown -R $USER:$USER $MAILDIR
fi

# Check if .muttrc file exists
if [ ! -f "/home/$USER/.muttrc" ] ; then
   # Create a .muttrc heredoc without parameter expansion
   echo "Creating a new .muttrc file" >> $email_logfile
   cat << 'EOT' > /home/$USER/.muttrc
set editor="nano"			# light weight emacs type editor
set hostname="winlink.org"
set alias_file=~/.mutt/aliases	# if you have an aliases file:
#source $alias_file		# load aliases

# Mail store stuff

set check_mbox_size=yes
set folder = $HOME/Mail     # All filenames reference from this
#set spoolfile=$HOME/Mail
mailboxes +inbox               # where to find new messages
set mbox_type=maildir          # the format e-mail is stored in
set edit_headers=yes
set autoedit = yes

set mbox=+inbox                # save incoming e-mail to inbox
set record=+sent               # save outgoing e-mail to sent
set postponed=+postponed
set move=ask-yes

set signature="$HOME/.signature.short"
set confirmappend = no
set smart_wrap = yes

folder-hook ipfilter set sort=threads
folder-hook . set sort=date-sent

# keybindings
# rebind delete to move the e-mail to the trash
macro index,pager   d "s+trash\n"  "Save the message to +trash"
bind index,pager    G imap-fetch-mail

# Headers to ignore
ignore *
unignore from date subject to cc bcc
unignore organization organisation
unignore posted-to: reply-to:
hdr_order date from to cc subject

set sendmail_wait =-1   	# don't wait to send an  e-mail
#  the -oem flag to cause errors to be mailed back;
#  the -oi flag to ignore dots in incoming messages
set sendmail="/usr/sbin/sendmail -oi -oem" # used on linux machine

set user_agent=no		# Don't set a "User-Agent" in header
set use_from=yes
EOT

   # Last 3 lines in .muttrc require parameter expansion

{
#   echo "set spoolfile=/var/mail/$USER"
   echo "set from=$CALLSIGN@winlink.org	# set default 'from:' address"
   echo "set realname=\"$REALNAME\""
   echo "my_hdr Reply-To: $CALLSIGN@winlink.org"
} >> /home/$USER/.muttrc
else
   echo ".muttrc file already exists" >> $email_logfile
fi

chown $USER:$USER /home/$USER/.muttrc
}

# ===== function outbox_check()
# Send msg & check for it in outbox

outbox_check() {

filecount_diff=0

# Postfix takes a while to deposit mail in outbox

filecountaf=$(ls -1 $outboxdir | wc -l)

if [ -z $filecountaf ] ; then
  filecountaf=0
fi

# Initialize current time
time_start=$(date +"%s")

# Loop until new file appears in outbox or it times out
while :
do
   filecountaf=$(ls -1 $outboxdir | wc -l)

   if [ -z $filecountaf ] ; then
      filecountaf=0
   fi

   if (( filecountaf > filecountb4 )) ; then
      break;
   fi

   time_current=$(date +"%s")
   timediff=$(($time_current - $time_start))
   if (( timediff > WAIT_TIME )) ; then
      break;
   fi
done

echo "file count b4: $filecountb4  after: $filecountaf in $timediff seconds"

filecount_diff=$((filecountaf - filecountb4))
if ((filecount_diff == 0)) ; then
   echo "Error: no change in filecount"
fi

return $filecount_diff
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

# Remove any old message files
if [ -e "$MSG_FILENAME" ] ; then
   rm $MSG_FILENAME
fi

# Create log file name
email_logfile="$TMPDIR/elog_$USER.txt"

echo "$scriptname started: $(date)" | tee $email_logfile
echo | tee -a $email_logfile

# has the mutt email program been installed
type -P $MUTT &>/dev/null
if [ $? -ne 0 ] ; then
   pkg_name="mutt"
   # Get here if mutt program NOT installed.
   echo "$scriptname: mutt not installed."
   # Test if mutt package has already been installed.
   is_pkg_installed $pkg_name
   if [ $? -ne 0 ] ; then
      echo "$scriptname: Will Install $pkg_name package"
      apt-get install -y -q $pkg_name
   fi
fi

chk_spool_file
config_mutt
get_last_maillog
echo " ==== chk_perm 1" >> $email_logfile
chk_perm
count_files_ob

# remove any old messages to be sent
if (( outboxfile_cnt > 0 )) ; then
   # purge the winlink outbox of old emails
   rm $PLU_VAR_DIR/outbox/*_$CALLSIGN
fi

echo " ==== send email to: $sendto_wl" >> $email_logfile
send_email $sendto_wl
echo " ==== send email to: $sendto_local"  >> $email_logfile
send_email $sendto_local
echo " ==== chk_perm 2" >> $email_logfile
chk_perm
count_files_ob
echo " ==== dump_maillog"  >> $email_logfile
dump_maillog
dump_files

echo | tee -a $email_logfile
echo "$scriptname finished: $(date)" | tee -a $email_logfile

# Count number of files in outbox directory
filecountb4=$(ls -1 $outboxdir | wc -l)
if [ -z $filecountb4 ] ; then
  filecountb4=0
fi

cp $email_logfile $MSG_FILENAME
send_email $sendto_wl

# Check if any mail is in outbox

outbox_check
if [ "$?" -gt 0 ] ; then
   $wl2ktransport
   retcode=$?
   if [ "$retcode" -ne 0 ]; then
      echo "$scriptname: $(date): $(basename $wl2ktransport) returned $retcode"
   fi
else
   echo "$scriptname: $(date): No mail found in winlink outbox"
fi

exit 0
