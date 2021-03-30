#!/bin/bash
#
#dire_ver=$(direwolf -v 2>/dev/null | grep -m 1 -i version | cut -d " " -f4)
dire_ver=$(direwolf -v 2>/dev/null | grep -m 1 -i version)
grep -i "development" <<< $dire_ver >/dev/null 2>&1
if [ "$?" -eq 0 ] ; then
    dire_verx=$(echo $dire_ver | cut -d " " -f5)
else
    dire_verx=$(echo $dire_ver | cut -d " " -f4)
fi

echo "Found direwolf version: ${dire_verx#*D} : D${dire_ver#*D}"

