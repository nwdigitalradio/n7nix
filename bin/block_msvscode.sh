#!/bin/bash
#
# block_msvscode.sh
#
# Used to prevent Microsoft repo being installed on a Raspberry Pi
# Reference:
#  https://www.cyberciti.biz/linux-news/heads-up-microsoft-repo-secretly-installed-on-all-raspberry-pis-linux-os/
#

FILE_MICROSOFT_KEY="/etc/apt/trusted.gpg.d/microsoft.gpg"
FILE_MICROSOFT_APT="/etc/apt/sources.list.d/vscode.list"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# function block Microsoft VS Code

function block_ms() {

    ## hosts file
    grep -iq "0.0.0.0 packages.microsoft.com" /etc/hosts
    if [ $? != 0 ] ; then
        sudo echo "0.0.0.0 packages.microsoft.com" | sudo tee -a  /etc/hosts
    fi

    ## gpg key
    # Delete Microsoft's GPG key
    if [[ -e "$FILE_MICROSOFT_KEY" ]] && [[ -s "$FILE_MICROSOFT_KEY" ]]  ; then
        echo "Removing Microsoft key"
        sudo rm -vf "$FILE_MICROSOFT_KEY"

        # Make sure new keys can NOT be installed
        echo "Making new empty Microsoft key file"
        sudo touch "$FILE_MICROSOFT_KEY"
        sudo chattr +i "$FILE_MICROSOFT_KEY"
    else
        echo "Microsoft key either does NOT exist OR is empty."
    fi

    # Verify file is write protected
    echo "Verify Microsoft gpg file is protected"
    lsattr "$FILE_MICROSOFT_KEY"

    ## package file
   grep -iq "^deb" $FILE_MICROSOFT_APT
   if [ $? = 0 ] ; then
        echo "Modifying Microsoft APT file"
        # Add a comment character for all lines in VSCode apt file
        sudo sed -i -e 's/^/#/' "$FILE_MICROSOFT_APT"
        if [ $? -ne 0 ] ; then
            echo "${FUNCNAME[0]}: sed failed on file: $FILE_MICROSOFT_APT"
        fi
    else
        echo "Microsoft APT file already modified."
    fi
}

# function detect if Microsoft has a gpg key & an apt repository entry

function is_microsoft() {

   grep -iq "^deb" $FILE_MICROSOFT_APT
   grepcode=$?
   dbgecho "File $FILE_MICROSOFT_APT : $grepcode"

   if [ $grepcode = 0 ] || ( [[ -f "$FILE_MICROSOFT_KEY" ]] && [[ -s "$FILE_MICROSOFT_KEY" ]] ) ; then
       echo "  Microsoft gpg key or repository entry IS active"
       retcode=0
   else
       echo "  Microsoft gpg key and repository entry NOT active"
       retcode=1
   fi

   return $retcode
}

# function block Microsoft files status

function block_ms_status() {

## Status of hosts file
FILE_HOSTS="/etc/hosts"
grep -iq "0.0.0.0 packages.microsoft.com" $FILE_HOSTS
if [ $? != 0 ] ; then
    echo "  File: $FILE_HOSTS has NOT been edited"
else
    echo "  File: $FILE_HOSTS OK, has been edited"
fi

# Status of Microsoft Key file
if [[ -f "$FILE_MICROSOFT_KEY" ]] ; then
    echo -n "  File: $FILE_MICROSOFT_KEY exists "
    if [[ -s "$FILE_MICROSOFT_KEY" ]] ; then
        echo "and is NOT empty"
    else
        echo "but IS empty"
    fi
else
    echo "  File: $FILE_MICROSOFT_KEY does NOT exist"
fi

# Status of Microsoft repo install file
   grep -iq "^deb" $FILE_MICROSOFT_APT
   if [ $? = 0 ] ; then
       echo "  File: $FILE_MICROSOFT_APT IS active"
   else
       echo "  File: $FILE_MICROSOFT_APT is NOT active"
   fi
}

# ===== main
# If there are any command line parameters just display status of of
# Microsoft files

echo "Test if Microsoft repo has been configured"

# Check for any command line arguments
if [[ $# -gt 0 ]] ; then
    block_ms_status
    exit 0
fi

if is_microsoft ; then
    dbgecho "  Will call block_ms"
    block_ms
else
    echo "  No files edited Microsoft repository already blocked."
fi
