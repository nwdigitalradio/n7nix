#!/bin/bash
#
# Install paclink-unix (with postfix & mutt) hostapd & dovecot
#
# Uncomment this statement for debug echos
DEBUG=1

echo "$myname: paclink-unix with imap install"
# First install basic paclink-unix
./plu_install.sh

# Install dovecot imap mail server
pushd ../mailserv
source ./imapserv_install.sh
popd

# Set up a host access point for remote operation
pushd ../hostap
source ./hostap_install.sh
popd

echo
echo "paclink-unix with imap install script FINISHED"
echo
