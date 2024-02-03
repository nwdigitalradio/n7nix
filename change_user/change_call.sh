#!/bin/bash
#
# Display call signs from:
#  axport

RMSGW_CFGDIR="/etc/rmsgw"
RMSGW_GWCFGFILE=$RMSGW_CFGDIR/gateway.conf


# tracker
echo "==== NIX tracker"
filename="/etc/tracker/aprs_tracker.ini"
if [ -e "$filename" ] ; then
    grep -i "^mycall" $filename
else
    echo "Filename: $filename does NOT exist"
fi

# direwolf
echo
echo "==== Direwolf"
filename="/etc/direwolf.conf"
if [ -e "$filename" ] ; then
    grep -i "^MYCALL" $filename
    grep -i "^IGLOGIN" $filename
else
    echo "Filename: $filename does NOT exist"
fi

# aprx
echo
echo "==== aprx"
filename="/etc/aprx.conf"
if [ -e "$filename" ] ; then
    grep -i "^mycall" $filename
    grep -i login $filename
else
    echo "Filename: $filename does NOT exist"
fi

# /etc/ax25/axports
echo
echo "==== AX.25 axports"
filename="/etc/ax25/axports"
if [ -e "$filename" ] ; then
    grep ^[^#] $filename
else
    echo "Filename: $filename does NOT exist"
fi

# Xastir
echo
echo "==== Xastir"
filename="$HOME/.xastir/config/xastir.cnf"
if [ -e "$filename" ] ; then
    grep -i "station_callsign" $filename
else
    echo "Filename: $filename does NOT exist"
fi

# paclink-unix
echo
echo "==== paclink-unix"
filename="/usr/local/etc/wl2k.conf"
if [ -e "$filename" ] ; then
    grep -i "^mycall" $filename
else
    echo "Filename: $filename does NOT exist"
fi

# paclink-unix
echo
echo "==== pat"
filename="$HOME/.config/pat/config.json"
if [ -e "$filename" ] ; then
    grep -i "\"mycall\"" $filename
else
    echo "Filename: $filename does NOT exist"
fi

# Linux RMS Gateway
echo
echo "==== RMS Gateway"
filename="$RMSGW_GWCFGFILE"
if [ -e "$filename" ] ; then
    grep -i "GWCALL" "$filename"
else
    echo "Filename: $filename does NOT exist"
fi
