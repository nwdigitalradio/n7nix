#!/bin/bash
#
# Manually create config files for DINAH:
#
#  /usr/local/etc/ax25
#    port.conf - verify contents
#    ax25d.conf - create new file
#    axports - create new file
#
# Edit direwolf config file
#  /etc/direwold.conf - edit existing file

DEBUG=1
CALLSIGN="N0ONE"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function validate_callsign
# Validate callsign

function validate_callsign() {

    callsign="$1"
    sizecallstr=${#callsign}

    if (( sizecallstr > 6 )) || ((sizecallstr < 3 )) ; then
        echo "Invalid call sign: $callsign, length = $sizecallstr"
        return 1
    fi

    # Convert callsign to upper case
    CALLSIGN=$(echo "$callsign" | tr '[a-z]' '[A-Z]')
    return 0
}

# ===== function get_callsign

function get_callsign() {
    retcode=0
    # Check if call sign var has already been set
    if [ "$CALLSIGN" == "N0ONE" ] ; then
        echo "Enter call sign, followed by [enter]:"
        read -e callsign
    else
        echo "Error: call sign: $CALLSIGN"
    fi
    validate_callsign $callsign
    if [ $? -eq 0 ] ; then
        retcode=1
    else
        echo "Bad callsign found: $callsign"
    fi
    return $retcode
}

# ===== function create_ax25d

function create_ax25d() {

#    sudo cat << "EOT" > $CFILE
sudo tee $CFILE > /dev/null << EOT
# /usr/local/etc/ax25/ax25d.conf
#
# ax25d Configuration File.
#
# Anyone connecting with the source call of N0CALL will be
# dropped. Everyone else is sent to the default.
#
# To route calls from a specific callsign to a different application,
# add them as desired.
#
# AX.25 Ports begin with a '['.
# Format is [<incoming callsign> VIA <axportname>]
#
# When users connect to <incoming callsign>, they will be processed
# by the section that matches.
#
[${CALLSIGN}-10 VIA dinah0]
NOCALL   * * * * * *  L
default  * * * * * *  - rmsgw /usr/local/bin/rmsgw rmsgw -P %d %U
#
[${CALLSIGN} VIA dinah0]
NOCALL   * * * * * *  L
default  * * * * * *  - pi /usr/local/bin/wl2kax25d wl2kax25d -c %U -a %d
EOT

}

# ===== function create_axports

function create_axports() {

# sudo cat << "EOT" > $CFILE

sudo tee $CFILE > /dev/null << EOT
# /usr/local/etc/ax25/axports
#
# The format of this file is:
#portname	callsign	speed	paclen	window	description
dinah0        ${CALLSIGN}-10            9600    255     2       Winlink port
dinah1        ${CALLSIGN}-1             9600    255     2       Direwolf port
EOT

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

    echo "sed check for MYCALL"
    grep "^MYCALL " $filename

    # Change IGLOGIN callsign
#    sed -ie "0,/^IGLOGIN /s/^IGLOGIN /IGLOGIN $CALLSIGN $logincode/" $filename

    # Returns logincode variable set
if [ 1 -eq 0 ] ; then
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
else
    # Comment out IGate login setting
    sudo sed -i 's/IGLOGIN*/# &/' $filename
fi
}


# === Main

    ## Get a callsign from command line
    echo "prompt for a callsign:"
    while get_callsign ; do
        retcode=$?
        echo "Input error ($retcode), try again"
    done

echo "CALLSIGN set to: $CALLSIGN"

# Verify port.conf file

    CFILE="/usr/local/etc/ax25/port.conf"
    echo
    echo " === Checking $CFILE file"

    DEVICE="$(grep -m1 "^Device=" $CFILE)"
    echo "$DEVICE"
    DEVICE=$(echo $DEVICE | cut -d'=' -f2)
    echo "DEVICE2: $DEVICE"
    # Replace udr device with dinah
    if [ $DEVICE = "udr" ] ; then
        echo "Found device udr"
        sudo sed -i -e "0,/^Device=/ s/^Device=.*/Device=dinah/" $CFILE
        if [ "$?" -ne 0 ] ; then
            echo "sed failed with var: Device in file: $CFILE"
        fi
    else
        echo "Found device $DEVICE"
    fi
    grep -m1 "^speed=" $CFILE
    grep -m1 "^receive_out=" $CFILE

# create axports file

CFILE="/usr/local/etc/ax25/axports"
echo " === Creating $CFILE with callsign $CALLSIGN"
create_axports

# create ax25d.conf file

CFILE="/usr/local/etc/ax25/ax25d.conf"
echo " === Creating $CFILE with callsign $CALLSIGN"
create_ax25d

set_direwolf


pushd "$HOME/n7nix/direwolf"

if [ -e "dw_config.sh" ] ; then
    ./dw_config.sh
else
    echo "Could not locat dw_config.sh in directory $pwd"
    echo " Direwolf configuration not complete"
fi

popd

echo
echo
echo " =========== ax25d.conf"
cat /usr/local/etc/ax25/ax25d.conf
echo " =========== axports"
cat /usr/local/etc/ax25/axports
echo "============ direwolf.conf"
grep ^[^#] /etc/direwolf.conf

echo "Finished setting up config files for USB sound device"