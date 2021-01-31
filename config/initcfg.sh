#!/bin/bash
#
# initcfg.sh
#
# Initial configuration for a fresh image.
#
# Run this script twice
# 1. Updates repos (n7nix & debian system) and runs app_config core
# 2. Installs Winlink programs & temperature graphs
#
# Uncomment this statement for debug echos
# DEBUG=1

scriptname="`basename $0`"
PORT_CFG_FILE="/etc/ax25/port.conf"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }


# ===== function check udrc enumeration

function check_udrc() {
    retcode=1
    CARDNO=$(aplay -l | grep -i udrc)

    if [ ! -z "$CARDNO" ] ; then
        dbgecho "udrc card number line: $CARDNO"
        CARDNO=$(echo $CARDNO | cut -d ' ' -f2 | cut -d':' -f1)
        echo "UDRC is sound card #$CARDNO"
        retcode=0
    else
	echo "$(tput setaf 1)$(tput bold) == No UDRC/DRAWS sound card found. $(tput sgr0)"
    fi
    return $retcode
}

#
# ===== Main
#

# Be sure NOT running as root
if [[ $EUID == 0 ]] ; then
    echo "Do not run as root"
    exit 0
fi

# ------ upgrade
# Verify UDRC device is enumerated
check_udrc
if [ $? -eq 1 ] ; then
    exit
fi

cd
cd n7nix
git pull
if [ $? -ne 0 ] ; then
    echo "$scriptname: Failure updating n7nix repository"
fi

cd config
./bin_refresh.sh

echo
echo "$(tput setaf 6) == RPi OS update$(tput sgr0)"
sudo apt-get -q update
if [ $? -ne 0 ] ; then
    echo "$scriptname: Failure updating n7nix repository"
fi
echo
echo "$(tput setaf 6) == RPi OS upgrade$(tput sgr0)"
sudo apt-get -q -y upgrade
if [ $? -ne 0 ] ; then
    echo "$scriptname: Failure updating n7nix repository"
fi
echo
echo "$(tput setaf 6) == RPi OS dist-upgrade$(tput sgr0)"
sudo apt-get -q -y dist-upgrade
if [ $? -ne 0 ] ; then
    echo "$scriptname: Failure updating n7nix repository"
fi

# reboot
# shutdown -r now

## ------ first config
# Verify if first config has already been done
# How many times has the app_config.sh core script been run?
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
CFG_FINISHED_MSG="core config script FINISHED"

runcnt=$(grep -c "$CFG_FINISHED_MSG" "$UDR_INSTALL_LOGFILE")
dbgecho "core_config.sh has been run $runcnt time(s)"

## ONLY do a config core once
if [ $runcnt -eq 0 ] ; then
    echo
    echo "$(tput setaf 6) === app_config CORE$(tput sgr0)"
    cd
    cd n7nix/config
    sudo ./app_config.sh core

    # reboot so new hostname takes effect
    echo
    echo "$(tput setaf 2) == First pass of initial config FINISHED, about to reboot $(tput sgr0)"
    echo "$(tput setaf 2) == If you run this script again it will install Winlink packet programs$(tput sgr0)"
    sudo shutdown -r now

else
    echo "Image core has already been configured ($runcnt time(s))"
fi

echo
echo "DEBUG: early exit"
exit

## ------ winlink config

echo
echo "$(tput setaf 6) === Config Winlink Programs$(tput sgr0)"
# Set radio to use discriminator
portnum=0

## ------ Set alsa parameters
echo
echo "$(tput setaf 6) == Set port number: $portnum for radio to use discriminator receive$(tput sgr0)"
sudo sed -i -e "/\[port$portnum\]/,/\[/ s/^receive_out=.*/receive_out=disc/" $PORT_CFG_FILE
setalsa-tmv71.sh

## ------ start AX.25 & direwolf
echo
echo "$(tput setaf 6) == Start AX25/direwolf stacks$(tput sgr0)"
ax25-start

echo
echo "$(tput setaf 6) == AX25/direwolf systemd service status$(tput sgr0)"
ax25-status

## ------ install paclink-unix
echo
echo "$(tput setaf 6) == Setup paclink-unix, postfix & dovecot$(tput sgr0)"
ax25-status

cd
cd n7nix/config
sudo ./app_config.sh plu

echo
echo "$(tput setaf 6) == Set up direwolf to 9600 baud packet$(tput sgr0)"

## ------ Verify 9600 baud packet works
speed_switch.sh -b 9600
alsa-show.sh
time wl2kax25 n7nix

## ------ Winlink packet station config finished

## ----- Install temperature RRD graph
echo
echo "$(tput setaf 6) == Install RPi activity & temperature graph$(tput sgr0)"

cd
cd dev/github/
git clone https://github.com/n7nix/rpi-temp-graph
cd rpi-temp-graph/
./tempgraph_install.sh

# Set proper GPIO for a DRAWS hat for ambient temperature
cd
cd bin

# Replace everything after string WIRINGPI_GPIO in file rpiamb_gettemp.sh
GPIO_NUM=21

sed -i -e "/WIRINGPI_GPIO=/ s/^WIRINGPI_GPIO=.*/WIRINGPI_GPIO=\"$GPIO_NUM\"/"  rpiamb_gettemp.sh
if [ "$?" -ne 0 ] ; then
    echo -e "\n\t$(tput setaf 1)Failed to change WIRINGPI_GPIO$(tput setaf 7)\n"
fi

## ----- Verify temperature value is going into database
echo
echo "$(tput setaf 6) == Check IP address$(tput sgr0)"

# Get IP address
ifconfig eth0

# in a browser verify temperature graph
# http://10.0.42.184/cgi-bin/rpitemp.cgi

## ----- Verify cpu & ambient temperature working

echo
echo "$(tput setaf 6) == Check temperature graph update in cron table$(tput sgr0)"
crontab -l

$ambtemp(rpiamb_gettemp.sh)
cputemp-$(rpicpu_gettemp.sh)
CPULOAD=$(cat /proc/loadavg | cut -f2 -d ' ')
echo "Temperatures: cpu: $cputemp, ambient: $ambtemp, cpu activity: $CPULOAD"
