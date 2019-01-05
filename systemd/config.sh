#!/bin/bash
#
ENABLE_AX25="false"

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

# ==== main

echo
echo "systemd config START"

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "$scriptname: Must be root to configure ... exiting"
   exit 1
fi

# Condition network services
systemctl enable systemd-networkd.service
systemctl enable systemd-networkd-wait-online.service

if [ "$ENABLE_AX25" = "true" ] ; then
    systemctl enable ax25dev.path
    systemctl enable direwolf.service
    # enable remaining ax25 services
    systemctl enable ax25d.service
    systemctl enable ax25-mheardd.service
fi

systemctl daemon-reload

echo "$(date "+%Y %m %d %T %Z"): $scriptname: systemd config script FINISHED" >> $UDR_INSTALL_LOGFILE
echo
echo "systemd config script FINISHED"
echo
