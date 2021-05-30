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

# ---------------------
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

    CALLPASS_DIR="$HOME/n7nix/direowlf"
    pushd $CALLPASS_DIR

    type -P ./callpass &>/dev/null
    if [ $? -ne 0 ] ; then
        echo "Building callpass"
        gcc -o callpass callpass.c

        # Check that callpass build was successful
        type -P ./callpass &>/dev/null
        if [ $? -ne 0 ] ; then
            echo
            echo "FAILED to build callpass"
            echo
        fi
    fi

    logincode=$(./callpass $CALLSIGN)
    popd

}

# ===== change_direwolf

function change_direwolf() {

    filename="/etc/direwolf.conf"

    # Change first occurrence of MYCALL
    sed -ie '0,/^MYCALL /s//MYCALL $CALLSIGN-1/' $filename

    # Change second occurrence of MYCALL
    sed -ie 's/^MYCALL /MYCALL $CALLSIGN-2/2' $filename

    # Change IGLOGIN callsign
#    sed -ie "0,/^IGLOGIN /s/^IGLOGIN /IGLOGIN $CALLSIGN $logincode/" $filename

    # Returns logincode variable set
    build_callpass

    # Get last argument in string
    logincode="${logincode##* }"
    echo "Login code for $CALLSIGN for APRS tier 2 servers: $logincode"

    # Changed per Doug Kingston's suggestion
    sed -i -e "/^[#]*IGLOGIN / s/^[#]*IGLOGIN .*/IGLOGIN $CALLSIGN $logincode\n/" $filename
    dbgecho "IGSERVER"
    sed -i -e "/#IGSERVER / s/^#//" $filename

}

# ===== backup_direwolf

function backup_direwolf() {

    filename="/etc/direwolf.conf"
    cp $filename $BACKUP_DIR
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

    # create temporary file
    tmpfile=$(mktemp /tmp/set_callsign.XXXXXX)

    echo
    echo " == Change call signs in $filename =="
    # remove last 2 lines
    head -n -2 $filename > $tmpfile
    PRIMARY_DEVICE="udr0"
    SSID_PRIME=1
    ALTERNATE_DEVICE="udr1"
    SSID_ALT=2

    {
echo "${PRIMARY_DEVICE}        $CALLSIGN-$SSID_PRIME            9600    255     2       Left port"
echo "${ALTERNATE_DEVICE}        $CALLSIGN-$SSID_ALT             9600    255     2       Right port"
} >> $tmpfile

    cp $tmpfile $filename
}

# ===== backup_ax25

function backup_ax25() {
    filename="/usr/local/etc/ax25/axports"
    cp $filename $BACKUP_DIR
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


#    sed -ie 's/\[img:.[^]]\]/\[img\]/g' file.txt
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


# ===== display_winlink
# wl2k.conf mycall

function display_winlink() {

    filename="$PLU_CFG_FILE"

    echo
    echo " == Call signs in $filename =="
    grep -i "^mycall" $filename
}

# ===== change_winlink

function change_winlink() {
   # Set mycall=
   sed -i -e "/mycall=/ s/mycall=.*/mycall=$CALLSIGN/" $PLU_CFG_FILE

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

# ===== set_callsigns

function set_callsigns() {

    set_ax25
    set_ax25d
    set_direwolf
    set_rmsgw
    set_winlink
    set_mutt
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

    backup_ax25

    filename="/usr/local/etc/ax25/ax25d.conf"
    cp $filename $BACKUP_DIR

    backup_direwolf

    filename="$RMSGW_GWCFGFILE"
    cp $filename $BACKUP_DIR
    filename="$RMSGW_CHANFILE"
    cp $filename $BACKUP_DIR

    filename="$PLU_CFG_FILE"
    cp $filename $BACKUP_DIR

    filename="$MUTT_CFG_FILE"
    cp $filename $BACKUP_DIR

    ls -salt $BACKUP_DIR
}

# ===== comare_config

function compare_config() {

    filename="/usr/local/etc/ax25/axports"
    diff $filename $BACKUP_DIR

    filename="/usr/local/etc/ax25/ax25d.conf"
    diff $filename $BACKUP_DIR

    filename="/etc/direwolf.conf"
    diff $filename $BACKUP_DIR

    filename="$RMSGW_GWCFGFILE"
    diff $filename $BACKUP_DIR
    filename="$RMSGW_CHANFILE"
    diff $filename $BACKUP_DIR

    filename="$PLU_CFG_FILE"
    diff $filename $BACKUP_DIR

    filename="$MUTT_CFG_FILE"
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
        echo "  -d              Set DEBUG flag"
        echo "  -h              Display this message."
        echo
	) 1>&2
	exit 1
}



# ===== main

# Default call sign
CALLSIGN="N0ONE"

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

    -s)
        # set new call signs
        set_callsigns
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
	fi
	verify_callsign
	set_callsigns
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
