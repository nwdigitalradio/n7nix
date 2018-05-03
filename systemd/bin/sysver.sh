#!/bin/bash
echo "----- /proc/version"
cat /proc/version
echo "----- /etc/*version"
cat /etc/*version
echo "----- /etc/*release"
cat /etc/*release
echo "----- lsb_release"
lsb_release -a
echo "---- systemd"
hostnamectl

verstr="$(direwolf -v 2>/dev/null |  grep -m 1 -i version)"
# Get rid of escape characters
echo "----- D${verstr#*D}"
