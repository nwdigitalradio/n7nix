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

# mutt
# set realname="Joe Blow"
# set from=callsign@winlink.org
# my_hdr Reply-To: callsign@winlink.org

# clawsmail
# pat
# tbird

# == aprs ==
# aprx
# tracker

# uronode

# ===== display_direwolf

function display_direwolf() {
    filename="/etc/direwolf.conf"

    echo
    echo " == Call signs in $filename =="

    # Squish all spaces
#    grep -v "^#" $filename | tr -s '[[:space:]]' | cut -f2 -d' '
    callsigns=$(grep "^MYCALL " $filename | tr -s '[[:space:]]' | cut -f2 -d' ')
    count=$(wc -l <<< $callsigns)

    echo "Number of Call signs in file $filename: $count"
    echo "$callsigns"
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


# ===== display_callsigns

function display_callsigns() {

    display_ax25
    display_ax25d
    display_direwolf

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
