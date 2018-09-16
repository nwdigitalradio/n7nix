#!/bin/bash
#
# Verify email configuration for winlink using postfix
#
scriptname="`basename $0`"
USER=$(whoami)

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

PLU_VAR_DIR="/usr/local/var/wl2k"
INDEX_FILENAME="$TMPDIR/indexfile.txt"
MSG_FILENAME="$TMPDIR/testmsg.txt"

MUTT="/usr/bin/mutt"
# Set boolean for this script generated email body
bgenbody="false"

# ===== function chk_perm
# Check permissions of the winlink outbox directory

function chk_perm() {
# set permissions for /usr/local/var/wl2k directory
# Check user & group of outbox directory
#
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

}

# ===== function count_files_ob
# count number of files in outbox
count_files_ob() {

# dump any files in winlink outbox to log file
if (( $filecount > 0 )) ; then
   echo " Files in outbox: $filecount for callsign: $CALLSIGN"
   outboxfiles=$(ls -1 ${PLU_VAR_DIR}/outbox/*_$CALLSIGN)
   if [ ! -z "$outboxfiles" ] ; then
      for filename in `echo ${outboxfiles}` ; do
         echo "==== email: $filename"
         cat $filename
         echo
      done
   else
      echo "No files for $CALLSIGN found"
      ls -1 ${PLU_VAR_DIR}/outbox/*_$CALLSIGN
   fi
else
   echo " No files in outbox"
fi
# dump request files here
}

# ===== function send_email
# Needs argument for who to send to
function send_email() {

sendto="$1"

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
}


# ===== function
get_last_maillog() {
   filename="/var/log/mail.log"
   last_ml=$(tail -n1 $filename)
   last_ln=$(wc -l $filename | cut -d ' ' -f1)
   echo "last line mail log[$last_ln]: $last_ml"
}


# ===== function get_mail_log
dump_maillog() {
   filename="/var/log/mail.log"
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
   sed -n $last_ln,\$p  $filename
   echo "mail.log end"
   echo
}

# ===== function chk_spool_file
chk_spool_file() {
if [ ! -e "$SPOOL_FILE" ] ; then
   echo "Spool file $SPOOL_FILE" does not exist!
   sudo touch $SPOOL_FILE
   sudo chown $USER:mail $SPOOL_FILE
else
   echo "Spool file $SPOOL_FILE" does exists
fi
ls -al /var/mail
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

if [ ! -f "/home/$USER/.muttrc" ] ; then
   echo "file: .muttrc NOT found"
else
   echo "file: .muttrc found existing"
fi

# Check if .muttrc file exists
if [ ! -f "/home/$USER/.muttrc" ] ; then
   # Create a .muttrc heredoc without parameter expansion
   echo "Creating a new .muttrc file"
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
   echo ".muttrc file already exists"
fi

chown $USER:$USER /home/$USER/.muttrc
}


# ===== main

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
chk_spool_file
config_mutt
get_last_maillog
echo " ==== chk_perm 1"
chk_perm
count_files_ob
# purge the winlink outbox of old emails
rm $PLU_VAR_DIR/outbox/*_$CALLSIGN

echo " ==== send email to: $sendto_wl"
send_email $sendto_wl
echo " ==== send email to: $sendto_local"
send_email $sendto_local
echo " ==== chk_perm 2"
chk_perm
count_files_ob
echo " ==== dump_maillog"
dump_maillog

exit 0
