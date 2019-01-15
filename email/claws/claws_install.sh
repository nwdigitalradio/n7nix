#!/bin/bash
#
# claws_install.sh [user_name] [callsign]
#
# claws-email needs to run so that the claws-mail setup wizard creates
# all the initial config files.
#
# Config claws-email for an imap server
# Edit these account setting variables
#
#  account_name=$USER@localhost
#  name=$REALNAME
#  address=$USER@$(hostname).localnet
#  user_id=$USER
#  signature_path=/home/$USER/.signature
#
DEBUG=1

scriptname="`basename $0`"
user=$(whoami)
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
CALLSIGN="N0ONE"

# ===== function dbgecho

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }


# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
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
   dbgecho " "
   dbgecho "using USER: $USER"
   dbgecho " "
}

# ===== get_tmp_fname

function get_tmp_fname() {

   fnameroot="$claws_mail_cfg_file"
   number=0
   suffix="$( printf -- '-%02d' "$number" )"

   while test -e "$fnameroot$suffix"; do
      (( ++number ))
      suffix="$( printf -- '-%02d' "$number" )"
   done

   fname="$fnameroot$suffix"

   echo "$fname"
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

# Don't be root
if [[ $EUID == 0 ]] ; then
   echo "Don't be root"
   exit 1
fi

# Save current directory
CUR_DIR=$(pwd)

echo "$scriptname: Installing claws-mail with UID: $EUID, user: $user"

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
   echo "USER=$USER, OK"
fi

# verify user name is legit
check_user

if [ $user != $USER ] ; then
   echo "Please login as $USER"
   exit 1
fi

pkg_name="claws-mail"
is_pkg_installed $pkg_name
if [ $? -ne 0 ] ; then
   echo "$scriptname: Will Install $pkg_name program"
   sudo apt-get -y install $pkg_name
   echo " claws-mail is now installed!"
   echo " NOW run claws-mail from GUI before proceeding."
   echo " This will create the claws-mail config files."
   echo " After running claws-mail, run this install script again."
   echo " See install notes in readme."
   exit 0
fi

# Check if claws-mail is running
# if 'pgrep' returns 0, the process is running
if pgrep claws-mail > /dev/null 2>&1 ; then

  echo "claws-mail program is running, exit claws-mail then re-run script."
  exit 1
fi

echo "Enter real name ie. Joe Blow, followed by [enter]:"
read -e REALNAME

get_callsign

# Edit the claws-mail config file
claws_mail_cfg_dir="/home/$USER/.claws-mail"
claws_mail_cfg_file="$claws_mail_cfg_dir/accountrc"

# Test if config file already exists

if [ -f "$claws_mail_cfg_file" ] ; then
   echo "Claws config file already exists"
   fname=$(get_tmp_fname)
   echo "Saving as: $fname"
   cp "$claws_mail_cfg_file" $fname
else
   echo "Creating new claws-mail config file: $claws_mail_cfg_file"
   if [ ! -d $claws_mail_cfg_dir ] ; then
      mkdir -p $claws_mail_cfg_dir
   fi
   cp accountrc "$claws_mail_cfg_file"
fi

echo "Change  name=$REALNAME"
sed -i -e "/name=/ s/name=.*/name=$REALNAME/" $claws_mail_cfg_file
echo "Change account_name=$USER@localhost"
sed -i -e "/account_name=/ s/account_name=.*/account_name=$USER@localhost/" $claws_mail_cfg_file
#echo "Change address=$USER@$(hostname).localnet"
echo "Change address=$CALLSIGN@winlink.org"
sed -i -e "/address=/ s/address=.*/address=$CALLSIGN@winlink.org/" $claws_mail_cfg_file
echo "Change user_id=$USER"
sed -i -e "/user_id=/ s/user_id=.*/user_id=$USER/" $claws_mail_cfg_file
echo "Change signature_path=/home/$USER/.signature"
sed -i -e "/signature_path=/ s/signature_path=.*/signature_path=\/home\/$USER\/\.signature/" $claws_mail_cfg_file
echo "Change smtp_user_id=$USER"
sed -i -e "/smtp_user_id=/ s/smtp_user_id=.*/smtp_user_id=$USER/" $claws_mail_cfg_file

# Enable the claws-mail desktop icon
cp /usr/share/raspi-ui-overrides/applications/claws-mail.desktop /home/$USER/Desktop

echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: claws-mail install script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
echo
# configure dovecot
sudo $CUR_DIR/dovecot_config.sh $USER
