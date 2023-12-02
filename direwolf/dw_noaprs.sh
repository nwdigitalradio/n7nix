#!/bin/bash
# Turn off all direwolf aprs activity

# If BBB is at the beginning of the line:
# sed 's/^BBB/#&/' -i file
#
# If BBB is in the middle of the line:
# sed 's/^[^#]*BBB/#&/' -i file

DW_CFGFILE="/etc/direwolf.conf"

grep "^IGLOGIN" $DW_CFGFILE
if [ $? -eq 0 ] ; then
    echo "Found active IGLOGIN"
else
    echo "No active IGLOGIN line found"
fi
grep "^IGSERVER" $DW_CFGFILE
if [ $? -eq 0 ] ; then
    echo "Found active IGSERVER"
else
    echo "No active IGSERVER line found"
fi


# $SED -i -e "s/^\(^ADEVICE1 .*\)/#\1/g"  $DIREWOLF_CFGFILE

# The & special character which references the whole matched portion of the pattern space
sudo sed -i -e 's/^IGLOGIN/# &/' $DW_CFGFILE
if [ $? -ne 0 ] ; then
    echo "Did NOT comment IGLOGIN line"
fi

sudo sed -i -e 's/^IGSERVER/# &/' $DW_CFGFILE
if [ $? -ne 0 ] ; then
    echo "Did NOT comment IGSERVER"
fi
