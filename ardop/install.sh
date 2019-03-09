#!/bin/bash
#
# Uncomment this statement for debug echos
# DEBUG=1

scriptname="`basename $0`"
user=$(whoami)
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

SRC_DIR="/usr/local/src/"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

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

# ===== main

echo -e "\n\t$(tput setaf 4) Install HF programs$(tput setaf 7)\n"

# Check for any arguments
if (( $# != 0 )) ; then
   USER="$1"
fi

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

# Check if user name was supplied on command line
if [ -z "$USER" ] ; then
    # prompt for call sign & user name
    # Check if there is only a single user on this system
    get_user
fi
# Verify user name
check_user

cd "$SRC_DIR"
download_filename="piARDOP_GUI"
sudo wget http://www.cantab.net/users/john.wiseman/Downloads/Beta/$download_filename
    if [ $? -ne 0 ] ; then
        echo -e "\n$(tput setaf 1)FAILED to download file: $download_filename$(tput setaf 7)\n"
    else
        echo -e "\n$(tput setaf 1)Need to install $download_filename $(tput setaf 7)\n"
    fi
fi

cd "$SRC_DIR"
download_filename="piardop2"
wget http://www.cantab.net/users/john.wiseman/Downloads/Beta/$download_filename
    if [ $? -ne 0 ] ; then
        echo -e "\n$(tput setaf 1)FAILED to download file: $download_filename$(tput setaf 7)\n"
    else
        echo -e "\n$(tput setaf 1)Need to install $download_filename $(tput setaf 7)\n"
    fi
fi

mod_file="/home/$USER/.asoundrc"
grep -i "pcm.ARDOP" $mod_file > /dev/null 2>&1
if [ $? -ne 0 ] ; then
    # Add to bottom of file
    cat << EOT >> $modfile

pcm.ARDOP {
        type rate
        slave {
        pcm "hw:1,0"
        rate 12000
        }
}
EOT
else
    echo -e "\n\t$(tput setaf 4)File: $mod_file NOT modified $(tput setaf 7)\n"
fi

arim_ver="2.6"
download_filename="arim-${arim_ver}.tar.gz"
ARIM_SRC_DIR=$SRC_DIR/arim-$arim_ver

# Should check if there is a previous installation

if [ ! -d "$ARIM_SRC_DIR" ] ; then
    cd "$SRC_DIR"

    sudo wget https://www.whitemesa.net/arim/src/$download_filename
        if [ $? -ne 0 ] ; then
            echo "$(tput setaf 1)FAILED to download file: $download_filename $(tput setaf 7)"
        else
            sudo tar xzvf $download_filename
            if [ $? -ne 0 ] ; then
                echo "$(tput setaf 1)FAILED to untar file: $download_filname $(tput setaf 7)"
            else
                sudo chown -R $USER:$USER $ARIM_SRC_DIR
                cd $ARIM_SRC_DIR
                ./configure
                echo -e "\n$(tput setaf 4)Starting arim build(tput setaf 7)\n"
                make
                echo -e "\n$(tput setaf 4)Starting arim install(tput setaf 7)\n"
                sudo make install
            fi
        fi
else
    echo -e "\n\t$(tput setaf 4)Using previously built arim-$arim_ver$(tput setaf 7)\n"
    echo
fi


echo
echo "$(date "+%Y %m %d %T %Z"): $scriptname: arim & ardop install script FINISHED" | sudo tee -a $UDR_INSTALL_LOGFILE
echo


