#!/bin/bash
#
# mutt_config.sh <user_name>
#
# Uncomment this statement for debug echos
DEBUG=1

scriptname="`basename $0`"
pkg_name="mutt"
CALLSIGN="N0ONE"
USER=
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function install_mutt

function install_mutt() {
    # Include gpgsm to mitigate: GPGME: CMS protocol not available
    PKG_REQUIRE_MUTT="mutt gpgsm"
    echo "$scriptname: Will Install $pkg_name package"
    sudo apt-get install -y -q $PKG_REQUIRE_MUTT
    sudo apt-mark auto gpgsm
}
# ===== function get_user

function get_user() {
   # Check if there is only a single user on this system
   if (( `ls /home | wc -l` == 1 )) ; then
      USER=$(ls /home)
   else
      echo "Enter user name ($(echo $USERLIST | tr '\n' ' ')), followed by [enter]:"
      read -e USER
   fi
}

# ==== function check_user
# verify user name is legit

function check_user() {
   userok=false
   dbgecho "$scriptname: Verify user name: $USER"
   for username in $USERLIST ; do
      if [ "$USER" = "$username" ] ; then
         userok=true;
      fi
   done

   if [ "$userok" = "false" ] ; then
      echo "User name ($USER) does not exist,  must be one of: $USERLIST"
      exit 1
   fi

   dbgecho "using USER: $USER"
}

# ===== function get_callsign

function get_callsign() {

if [ "$CALLSIGN" == "N0ONE" ] ; then
   echo "Enter call sign, followed by [enter]:"
   read -e CALLSIGN

   sizecallstr=${#CALLSIGN}

   if (( sizecallstr > 6 )) || ((sizecallstr < 3 )) ; then
      echo "Invalid call sign: $CALLSIGN, length = $sizecallstr"
      exit 1
   fi

   # Convert callsign to upper case
   CALLSIGN=$(echo "$CALLSIGN" | tr '[a-z]' '[A-Z]')
fi

dbgecho "Using CALL SIGN: $CALLSIGN"
}

# ===== main

echo
echo "=== mutt config START"

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

# if there are any args on command line assume it's
# user name & callsign
if (( $# != 0 )) ; then
   USER="$1"
   if (( $# == 2 )) ; then
      CALLSIGN="$2"
   fi
else
   get_user
fi

if [ -z "$USER" ] ; then
   echo "USER string is null, get_user"
   get_user
else
   echo "USER=$USER not null"
fi

check_user

# Check for a valid callsign
get_callsign

# Check if mutt has been installed
program_name="mutt"
type -P $program_name  &>/dev/null
if [ $? -ne 0 ] ; then
   echo "$scriptname: Program: $program_name not found in path ... installing"
   install_mutt
else
   dbgecho "Program: $program_name  found"
fi

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
if [ ! -f .muttrc ] ; then
   # Create a .muttrc heredoc without parameter expansion
   echo "Make a .muttrc file"
   cat << 'EOT' > /home/$USER/.muttrc
set editor="nano"			# light weight emacs type editor
set hostname="winlink.org"
set alias_file=~/.mutt/aliases	# if you have an aliases file:
#source $alias_file		# load aliases

# Mail store stuff

set check_mbox_size=yes
set folder = $HOME/Mail     # All filenames reference from this
set spoolfile=$HOME/Mail
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
   echo "Enter real name ie. Joe Blow, followed by [enter]:"
   read -e REALNAME

{
   echo "set from=$CALLSIGN@winlink.org	# set default 'from:' address"
   echo "set realname=\"$REALNAME\""
   echo "my_hdr Reply-To: $CALLSIGN@winlink.org"
} >> /home/$USER/.muttrc
else
   echo ".muttrc file already exists"
fi

chown $USER:$USER /home/$USER/.muttrc

echo "$(date "+%Y %m %d %T %Z"): $scriptname: mutt config script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "mutt config FINISHED"
echo