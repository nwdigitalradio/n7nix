#!/bin/bash
#
echo "----- image version"
head -n 1 /var/log/udr_install.log
echo "----- /proc/version"
cat /proc/version
echo "----- /etc/*version: $(cat /etc/*version)"
echo "----- /etc/*release"
cat /etc/*release
echo "----- lsb_release"
lsb_release -a
echo "---- systemd"
hostnamectl
echo "---- modules"
lsmod | egrep -e '(udrc|tlv320)'
dkmsdir="/lib/modules/$(uname -r)/updates/dkms"
echo
if [ -d "$dkmsdir" ] ; then
   ls -o $dkmsdir/udrc.ko $dkmsdir/tlv320aic32x4*.ko
else
   echo "Command 'apt-get install udrc-dkms' failed or was not run."
fi
echo "---- kernel"
dpkg -l "*kernel" | tail -n 3

echo
# Check version of direwolf installed
type -P direwolf &>/dev/null
if [ $? -ne 0 ] ; then
   echo "----- No direwolf program found in path"
else
   verstr="$(direwolf -v 2>/dev/null |  grep -m 1 -i version)"
   # Get rid of escape characters
   echo "----- D${verstr#*D}"
fi
