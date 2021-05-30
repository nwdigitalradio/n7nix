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

RMSGW_CFGDIR="/etc/rmsgw"
RMSGW_GWCFGFILE=$RMSGW_CFGDIR/gateway.conf
RMSGW_CHANFILE=$RMSGW_CFGDIR/channels.xml

PLU_CFG_FILE="/usr/local/etc/wl2k.conf"

MUTT_CFG_FILE="$HOME/.muttrc"


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

# ===== change_direwolf

function change_direwolf() {
    filename="/etc/direwolf.conf"

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



# ===== display_callsigns

function display_callsigns() {

    display_ax25
    display_ax25d
    display_direwolf
    display_rmsgw
    display_winlink
    display_mutt

}

usage () {
	(
	echo "Usage: $scriptname [-p][-d][-h]"
        echo "                  No args will display call signs configured"
        echo "  -p              Print call signs used"
        echo "  -d              Set DEBUG flag"
        echo "  -h              Display this message."
        echo
	) 1>&2
	exit 1
}



# ===== main


while [[ $# -gt 0 ]] ; do
APP_ARG="$1"

case $APP_ARG in

    -p)
        # display call signs
        display_callsigns
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
