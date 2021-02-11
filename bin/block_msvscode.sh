#!/bin/bash
#
# block_msvscode.sh
#
# Used to prevent Microsoft repo being installed on a Raspberry Pi
# Reference:
#  https://www.cyberciti.biz/linux-news/heads-up-microsoft-repo-secretly-installed-on-all-raspberry-pis-linux-os/
#
scriptname="`basename $0`"
VERSION="1.1"

FILE_MICROSOFT_KEY="/etc/apt/trusted.gpg.d/microsoft.gpg"
FILE_MICROSOFT_APT="/etc/apt/sources.list.d/vscode.list"
FILE_HOSTS="/etc/hosts"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# function make a benign Microsoft VS Code apt file

function make_benign_msaptfile() {

    sudo tee "$FILE_MICROSOFT_APT" > /dev/null << EOF
#### THIS FILE IS AUTOMATICALLY CONFIGURED ###
## You may comment out this entry, but any other modifications may be lost.
#deb [arch=amd64,arm64,armhf] http://packages.microsoft.com/repos/code stable main
EOF
}

# ===== function make an empty Microsoft VS Code key file

function make_empty_mskeyfile() {

    if [ -f "$FILE_MICROSOFT_KEY" ] ; then
        echo "Removing Microsoft key"
        sudo rm -vf "$FILE_MICROSOFT_KEY"
    fi

    # Make sure new keys can NOT be installed
    echo "  Making new empty Microsoft key file"
    sudo touch "$FILE_MICROSOFT_KEY"
    sudo chattr +i "$FILE_MICROSOFT_KEY"

}

# ===== function block Microsoft VS Code

function block_ms() {

    ## hosts file
    grep -iq "0.0.0.0 packages.microsoft.com" $FILE_HOSTS
    if [ $? != 0 ] ; then
        echo "0.0.0.0 packages.microsoft.com" | sudo tee -a $FILE_HOSTS
    fi

    ## gpg key
    # Delete Microsoft's GPG key
    if [[ -e "$FILE_MICROSOFT_KEY" ]] && [[ -s "$FILE_MICROSOFT_KEY" ]]  ; then
        make_empty_mskeyfile
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

# ===== function detect if Microsoft has a gpg key & an apt repository entry

function is_microsoft() {

   grepcode=1
   if [ -f $FILE_MICROSOFT_APT ] ; then
       grep -iq "^deb" $FILE_MICROSOFT_APT
       grepcode=$?
       dbgecho "File $FILE_MICROSOFT_APT : $grepcode"
       APT_FILE_EXISTS=true
   else
       echo "  File: $FILE_MICROSOFT_APT does NOT exist"
       APT_FILE_EXISTS=false
   fi

   retcode=1

   if [ -f "$FILE_MICROSOFT_KEY" ] ; then
       KEY_FILE_EXISTS=true

       if [ $grepcode = 0 ] || [[ -s "$FILE_MICROSOFT_KEY" ]] ; then
           echo "  Microsoft gpg key or repository entry IS active"
           retcode=0
       else
           echo "  Microsoft gpg key and repository entry NOT active"
       fi
   else
       echo "  File: $FILE_MICROSOFT_KEY does NOT exist"
       KEY_FILE_EXISTS=false
   fi

   return $retcode
}

# ===== function block Microsoft files status

function block_ms_status() {

## Status of hosts file

grep -iq "0.0.0.0 packages.microsoft.com" $FILE_HOSTS
if [ $? != 0 ] ; then
    echo "  File: $FILE_HOSTS has NOT been edited"
else
    echo "  File: $FILE_HOSTS OK, has been edited"
fi

## Status of Microsoft Key file
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

## Status of Microsoft repo install file
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

echo "${scriptname} ver: ${VERSION}: Test if Microsoft repo has been configured"

# Check for any command line arguments
if [[ $# -gt 0 ]] ; then
    block_ms_status
    exit 0
fi

# Check if Microsoft repo file already exists
if is_microsoft ; then
    dbgecho "  Will call block_ms"
    block_ms
else
    if [[ $KEY_FILE_EXISTS = true ]] && [[ $KEY_FILE_EXISTS = true ]] ; then
        echo "  No files edited Microsoft repository already blocked."
    else
        # Case where msvscode has not been added to repository yet.
        ## hosts file
        grep -iq "0.0.0.0 packages.microsoft.com" $FILE_HOSTS
        if [ $? != 0 ] ; then
            echo "0.0.0.0 packages.microsoft.com" | sudo tee -a $FILE_HOSTS
        fi

        ## gpg key
        make_empty_mskeyfile

	## package file
	make_benign_msaptfile
        echo "  1 file edited, 2 files created Microsoft repository now blocked."
    fi
fi
