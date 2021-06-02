#!/bin/bash
#
# Change call sign in the following configs:
#

# Files that contain callsign

# == Direwolf ==
# Uses MYCALL NOCALL
# /etc/direwolf.conf

# == AX.25 ==
# Uses portname callsign speed paclen window description
# /usr/local/etc/ax25/axports

# Uses [N0ONE VIA $intface]
# /etc/ax25/ax25d.conf

# == RMS Gateway ==
# Uses GWCALL=N0CALL
# /etc/rmsgw/gateway.conf

# Uses basecall N0CALL, callsign NOCALL
# password
# gridsquare
# /etc/rmsgw/channels.xml

# == Winlink ==
# paclink-unix uses mycall=N0ONE
# /usr/local/etc/wl2k.conf

# == mutt ==
# set realname="Joe Blow"
# set from=callsign@winlink.org
# my_hdr Reply-To: callsign@winlink.org

# Unfinished ---------------------
#
# clawsmail
# pat
# tbird

# == aprs ==
# aprx
# tracker

# uronode
#
# ---------------------
DEBUG=

# Default call sign
CALLSIGN="N0ONE"
REALNAME="Joe Blow"

# Default real name

BACKUP_DIR="$HOME/cfg_backup"

RMSGW_CFGDIR="/etc/rmsgw"
RMSGW_GWCFGFILE=$RMSGW_CFGDIR/gateway.conf
RMSGW_CHANFILE=$RMSGW_CFGDIR/channels.xml

PLU_CFG_FILE="/usr/local/etc/wl2k.conf"

MUTT_CFG_FILE="$HOME/.muttrc"


function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function get_callsign

function verify_callsign() {

   sizecallstr=${#CALLSIGN}

   if (( sizecallstr > 6 )) || ((sizecallstr < 3 )) ; then
      echo "Invalid call sign: $CALLSIGN, length = $sizecallstr"
      exit 1
   fi

    # Convert callsign to upper case
    CALLSIGN=$(echo "$CALLSIGN" | tr '[a-z]' '[A-Z]')


    dbgecho "Using CALL SIGN: $CALLSIGN"
}


# ===== display_direwolf

function display_direwolf() {
    filename="/etc/direwolf.conf"

    echo
    echo " == Call signs in $filename =="

    # Squish all spaces
#    grep -v "^#" $filename | tr -s '[[:space:]]' | cut -f2 -d' '
    callsigns=$(grep "^MYCALL " $filename | tr -s '[[:space:]]' | cut -f2 -d' ')


    ig_callsign=$(grep "^IGLOGIN " $filename | tr -s '[[:space:]]' | cut -f2 -d' ')
#    echo "ig callsign: $ig_callsign"
    callsigns=$(printf "%s\n%s\n" $callsigns $ig_callsign)

    count=$(wc -l <<< $callsigns)
    echo "Number of Call signs in file $filename: $count"
    echo "$callsigns"
}


# ===== build_callpass
# Igates need a code so they can log into the tier 2 servers.
# It is based on your callsign, and there is a utility called
# callpass in Xastir that will compute it.

function build_callpass() {

    CALLPASS_DIR="$HOME/n7nix/direwolf"
    pushd $CALLPASS_DIR > /dev/null

    type -P ./callpass &>/dev/null
    if [ $? -ne 0 ] ; then
        echo "Building callpass"
        gcc -o callpass callpass.c

        # Check that callpass build was successful
        type -P ./callpass &>/dev/null
        if [ $? -ne 0 ] ; then
            echo
            echo "$(tput setaf 1)FAILED to build callpass$(tput sgr0)"
            echo
        fi
    fi

    logincode=$(./callpass $CALLSIGN)
    popd > /dev/null
}

# ===== set_direwolf

function set_direwolf() {

    filename="/etc/direwolf.conf"

    # Change first occurrence of MYCALL
    dbgecho "sed First occurrence of MYCALL: $CALLSIGN-1"
    sudo sed -ie "0,/^MYCALL /s/^MYCALL .*/MYCALL $CALLSIGN-1/" $filename

    # Change second occurrence of MYCALL
    dbgecho "sed Second occurrence of MYCALL: $CALLSIGN-2"
    # sudo sed -ie 's/^MYCALL .*/MYCALL $CALLSIGN-2/2' $filename
    sudo sed -ie "0,/^MYCALL/! {0,/^MYCALL/ s/^MYCALL .*/MYCALL $CALLSIGN-2/}" $filename

    dbgecho "sed check"
    grep "^MYCALL " $filename

    # Change IGLOGIN callsign
#    sed -ie "0,/^IGLOGIN /s/^IGLOGIN /IGLOGIN $CALLSIGN $logincode/" $filename

    # Returns logincode variable set
    build_callpass

    # Get last argument in string
    logincode="${logincode##* }"
    echo "Login code for $CALLSIGN for APRS tier 2 servers: $logincode"

    # Changed per Doug Kingston's suggestion
    dbgecho "sed IGLOGIN"
    sudo sed -i -e "/^[#]*IGLOGIN / s/^[#]*IGLOGIN .*/IGLOGIN $CALLSIGN $logincode\n/" $filename
    if [ ! -z "$DEBUG" ] ; then
        grep "^IGLOGIN" $filename
    fi
    # Uncomment IGate server setting
    sudo sed -i -e "/#IGSERVER / s/^#//" $filename
}


# ===== display_ax25

function display_ax25() {
    filename="/usr/local/etc/ax25/axports"

    echo
    echo " == Call signs in $filename =="

    # Squish all spaces
#    grep -v "^#" $filename | tr -s '[[:space:]]' | cut -f2 -d' '
    callsigns=$(grep -v "^#" $filename | tr -s '[[:space:]]' | cut -f2 -d' ')
    count=$(wc -l <<< $callsigns)

    echo "Number of Call signs in file $filename: $count"
    echo "$callsigns"
}

# ===== set_ax25

function set_ax25() {
    filename="/usr/local/etc/ax25/axports"

    echo
    echo " == Change call signs in $filename =="
    # remove last 2 lines
    head -n -2 $filename > $tmpfile
    PRIMARY_DEVICE="udr0"
    SSID_PRIME=1
    ALTERNATE_DEVICE="udr1"
    SSID_ALT=2

    {
echo "${PRIMARY_DEVICE}        $CALLSIGN-$SSID_PRIME             9600    255     2       Left port"
echo "${ALTERNATE_DEVICE}        $CALLSIGN-$SSID_ALT             9600    255     2       Right port"
} >> $tmpfile

    sudo cp $tmpfile $filename
}


# ===== display_ax25d

function display_ax25d() {

    filename="/usr/local/etc/ax25/ax25d.conf"
    echo
    echo " == Call signs in $filename =="

    # Squish all spaces
#    grep -v "^#" $filename | tr -s '[[:space:]]' | cut -f2 -d' '
    callsigns=$(grep -v "^#" $filename | tr -s '[[:space:]]' | grep "^\[" | cut -f1 -d' ')
    count=$(wc -l <<< $callsigns)

    callsigns=$(echo "$callsigns" | sed 's/\[//g')
#    callsigns=$(echo "$callsigns" | xargs -0 | sed 's/\[//g')
#    callsigns=$(echo "$callsigns" | tr -d "[")
#    callsigns=$(echo "$callsigns")

    echo "Number of Call signs in file $filename: $count"
    echo "$callsigns"
}

# ===== set_ax25d

function set_ax25d() {

    filename="/usr/local/etc/ax25/ax25d.conf"
    echo
    echo " == Call signs in $filename =="

    # First match ONLY
    sudo sed -ie "0,/^\[/ s/^\[.*/\[$CALLSIGN-10 VIA udr0\]/" $filename

    # https://www.linuxquestions.org/questions/programming-9/replace-2nd-occurrence-of-a-string-in-a-file-sed-or-awk-800171/
    # You seem to be thinking of the second occurrence based on each line
    # being an occurrence, but sed sees it as the number of occurrences on
    # a single line:
    # Second match ONLY
#   sudo sed ':a;N;$!ba;s/dog/big_dog/2'
    sudo sed -ie "0,/^\[/! {0,/^\[/ s/^\[.*/\[$CALLSIGN VIA udr0\]/}" $filename
}

# ===== display_rmsgw
# channels.xml: basecall, callsign
# gateway.conf: GWCALL

function display_rmsgw() {

    filename="$RMSGW_GWCFGFILE"

    echo
    echo " == Call signs in $filename =="
    grep -i "GWCALL" "$filename"

    filename="$RMSGW_CHANFILE"

    echo
    echo " == Call signs in $filename =="

    # Remove html tags & preceding white space
    grep -i "<basecall" $filename  | sed -e 's/<[^>]*>//g' | sed 's/^[ \t]*//'
    grep -i "<callsign" $filename  | sed -e 's/<[^>]*>//g' | sed 's/^[ \t]*//'
}

# ===== set_rmsgw

function set_rmsgw() {

    filename="$RMSGW_GWCFGFILE"

    echo
    echo " == Change call sign in $filename =="
    sudo sed -ie "/GWCALL=/s/^GWCALL=.*/GWCALL=$CALLSIGN-10/g" $filename

    filename="$RMSGW_CHANFILE"
    echo
    echo " == Change call sign in $filename =="

    sudo sed -ie "/<basecall>/s/<basecall>.*/<basecall>$CALLSIGN<basecall>/g" $filename
    sudo sed -ie "/<callsign>/s/<callsign>.*/<callsign>$CALLSIGN-10<callsign>/g" $filename
}


# ===== display_winlink
# wl2k.conf mycall

function display_winlink() {

    filename="$PLU_CFG_FILE"

    echo
    echo " == Call signs in $filename =="
    grep -i "^mycall" $filename
}

# ===== set_winlink

function set_winlink() {
    filename="$PLU_CFG_FILE"
   # Set mycall=
   sudo sed -i -e "/mycall=/ s/mycall=.*/mycall=$CALLSIGN/" $PLU_CFG_FILE
}

# mutt
# set realname="Joe Blow"
# set from=callsign@winlink.org
# my_hdr Reply-To: callsign@winlink.org

# ===== display_mutt
# .mutrc set realname=, set from=, my_hdr

function display_mutt() {

    filename="$MUTT_CFG_FILE"

    echo
    echo " == Call signs in $filename =="
    grep -i "^set realname=" $filename | cut -f2 -d'='
    grep -i "^set from=" $filename |  cut -f2 -d'=' | sed -E 's@[[:blank:]]*(//|#).*@@;T;/./!d'
    grep -i "^my_hdr Reply-To:" $filename | cut -f3 -d' '
}

# ===== set_mutt

function set_mutt() {

    filename="$MUTT_CFG_FILE"
    # Set from=
    sudo sed -ie "/set from=/ s/^set from=.*/set from=$CALLSIGN@winlink.org/" $MUTT_CFG_FILE
    # Set realname
    sudo sed -ie "/set realname=/ s/^set realname=.*/set realname=\"$REALNAME\"/" $MUTT_CFG_FILE

    # my_hdr Reply-To:
    sudo sed -ie "/my_hdr Reply-To:/ s/^my_hdr Reply-To:.*/my_hdr Reply-To: $CALLSIGN@winlink.org/" $MUTT_CFG_FILE
}


# ===== set_callsigns

function set_callsigns() {

    # create temporary file
    tmpfile=$(mktemp /tmp/set_callsign.XXXXXX)

    set_ax25
    set_ax25d
    set_direwolf
    set_rmsgw
    set_winlink
    set_mutt

    rm $tmpfile
}


# ===== display_callsigns

function display_callsigns() {

    display_ax25
    display_ax25d
    display_direwolf
    display_rmsgw
    display_winlink
    display_mutt
}

# ===== backup_config

function backup_config() {

    if [ ! -d $BACKUP_DIR ] ; then
        mkdir -p $BACKUP_DIR
    fi

    filename="/usr/local/etc/ax25/axports"
    cp $filename $BACKUP_DIR

    filename="/usr/local/etc/ax25/ax25d.conf"
    cp $filename $BACKUP_DIR

    filename="$RMSGW_GWCFGFILE"
    cp $filename $BACKUP_DIR
    filename="$RMSGW_CHANFILE"
    cp $filename $BACKUP_DIR

    filename="/etc/direwolf.conf"
    cp $filename $BACKUP_DIR

    filename="$PLU_CFG_FILE"
    cp $filename $BACKUP_DIR

    filename="$MUTT_CFG_FILE"
    cp $filename $BACKUP_DIR

    ls -salt $BACKUP_DIR
}

# ===== restore_config from previous back-up

function restore_config() {

    if [ ! -d $BACKUP_DIR ] ; then
       echo "Nothing to restore"
       exit 1
    fi

    filename="/usr/local/etc/ax25/axports"
    sudo cp $BACKUP_DIR/$(basename $filename) $filename

    filename="/usr/local/etc/ax25/ax25d.conf"
    sudo cp $BACKUP_DIR/$(basename $filename) $filename

    filename="$RMSGW_GWCFGFILE"
    sudo cp $BACKUP_DIR/$(basename $filename) $filename
    filename="$RMSGW_CHANFILE"
    sudo cp $BACKUP_DIR/$(basename $filename) $filename

    filename="/etc/direwolf.conf"
    sudo cp $BACKUP_DIR/$(basename $filename) $filename

    filename="$PLU_CFG_FILE"
    sudo cp $BACKUP_DIR/$(basename $filename) $filename

    filename="$MUTT_CFG_FILE"
    sudo cp $BACKUP_DIR/$(basename $filename) $filename

    if [ 1 -eq 0 ] ; then
        dbgecho "Do nothing"
    fi
}


# ===== diff files that have been previously backed up

function compare_config() {

    filename="/usr/local/etc/ax25/axports"
    echo " == Call Signs in $filename =="
    diff $filename $BACKUP_DIR

    filename="/usr/local/etc/ax25/ax25d.conf"
    echo " == Call Signs in $filename =="
    diff $filename $BACKUP_DIR

    filename="/etc/direwolf.conf"
    echo " == Call Signs in $filename =="
    diff $filename $BACKUP_DIR

    filename="$RMSGW_GWCFGFILE"
    echo " == Call Signs in $filename =="
    diff $filename $BACKUP_DIR
    filename="$RMSGW_CHANFILE"
    echo " == Call Signs in $filename =="
    diff $filename $BACKUP_DIR

    filename="$PLU_CFG_FILE"
    echo " == Call Signs in $filename =="
    diff $filename $BACKUP_DIR

    filename="$MUTT_CFG_FILE"
    echo " == Call Signs in $filename =="
    diff $filename $BACKUP_DIR
}

# ===== function usage

usage () {
	(
	echo "Usage: $scriptname [-p][-d][-h]"
        echo "                  No args will display call signs configured"
        echo "  -p              Print call signs used"
	echo "  -s <callsign>   Set new callsign"
	echo "  -B              Backup config files"
	echo "  -D              Diff config files"
	echo "  -R              Resotre config files"
        echo "  -d              Set DEBUG flag"
        echo "  -h              Display this message."
	echo "  -t              Debug test"
        echo
	) 1>&2
	exit 1
}



# ===== main

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    dbgecho "*** Running as user: $(whoami) ***" 2>&1
else
    echo "DO NOT run as root"
    exit 0
fi

while [[ $# -gt 0 ]] ; do
APP_ARG="$1"

case $APP_ARG in

    -B)
        # Backup config files
        backup_config
	exit 0
    ;;

    -D)
        # Compare config files with diff
        compare_config
	exit 0
    ;;

    -R)
        # restore config files from backup
        restore_config
	exit 0
    ;;

    -p)
        # display call signs
        display_callsigns
	exit 0
    ;;
    -s)
        CALLSIGN="$2"
	if [ -z $CALLSIGN ] ; then
            CALLSIGN="N0ONE"
	    REALNAME="Joe Blow"
	else
            echo "Enter real name for Winlink mail config, ie. Joe Blow, followed by [enter]:"
            read -e REALNAME
	fi

	verify_callsign
	set_callsigns
	exit 0
    ;;
    -t)
        DEBUG=1
        echo " ==== Set test ===="
        set_direwolf
	echo
        echo " ==== Display check ===="
        display_direwolf
	exit 0
    ;;
    -h|--help|-?)
        usage
        exit 0
   ;;
   *)
        echo "Unrecognized command line argument: $APP_ARG"
        usage
        exit 0
   ;;

esac

shift # past argument
done

echo "No args used"
display_callsigns

exit 0
