#!/bin/bash
#
# cpu_util.sh
#
# Script to determine why CPU utilization is so high

echo "== pi version"
piver.sh

echo
echo "== direwolf version"
prog_name="dw_ver.sh"
type -P $prog_name &>/dev/null
if [ $? -ne 0 ] ; then
    prog_path="$HOME/n7nix/direwolf"
    cp $prog_path/$prog_name $HOME/bin
    if [ $? -ne 0 ] ; then
        echo "$(tput setaf 1)Script($prog_path/$prog_name) not found$(tput sgr0)"
    fi
fi
dw_ver.sh

echo
echo "== pulseaudio version"
pulseaudio --version

echo
echo "== pulseaudio status"
service="pulseaudio"
systemctl --system is-active "$service" > /dev/null 2>&1
if [ $? -eq 0 ] ; then
    systemctl --system --no-pager status $service
fi

systemctl --user is-active "$service" > /dev/null 2>&1
if [ $? -eq 0 ] ; then
    systemctl --user --no-pager status $service
fi

echo
echo "== cpu utilization"
ps aux | sort -nrk 3,3 | head -n 5

prog_name="mpstat"
type -P $prog_name &>/dev/null
if [ $? -ne 0 ] ; then
    echo
    echo "Installing sysstat package"
    sudo apt-get -qq install -y sysstat
    if [ $? -ne 0 ] ; then
        echo "ERROR: problem installing sysstat package"
	exit 1
    fi
fi

echo
echo "== ALL cpu utilizations"
mpstat -P ALL