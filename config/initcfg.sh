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
# Use this script to bring up some packet capability
#   - used to easily test NWDR image functionality
# - Besides core app config will also install/configure:
#   paclink-unix
#     mutt
#     claws-mail
#     rainloop
#   nodejs
#   lighttpd
#   postfix
#   dovecott
#   rpi-temp-graph
#
#
# Uncomment this statement for debug echos
# DEBUG=1

scriptname="`basename $0`"
PORT_CFG_FILE="/etc/ax25/port.conf"
radio="tmv71a"
user=$(whoami)

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

# ===== function package_update_only
# Only update the package list, do not install anything

function package_update_only() {
    # time how long this takes
    begin_sec=$SECONDS

    echo
    echo "$(tput setaf 6) == RPi File System UPDATE$(tput sgr0)"
    sudo apt-get -q update
    if [ $? -ne 0 ] ; then
        echo "$scriptname: Failure UPDATING file system packages"
    fi

    # Display how long this took
    echo "$(tput setaf 2) == System update finished in $((SECONDS-begin_sec)) seconds$(tput sgr0)"
}

# ===== function package_upgrade_only
# Do a package upgrade AFTER package update
### 01/2021 do NOT want to install kernel 5.10.11-v7l+ *1399
# begin_secs var set in package_update_only()

function package_upgrade_only() {

    echo
    echo "$(tput setaf 6) == RPi File System UPGRADE$(tput sgr0)"
    sudo apt-get -q -y upgrade
    if [ $? -ne 0 ] ; then
        echo "$scriptname: Failure UPGRADING file system packages"
    fi
    echo
    echo "$(tput setaf 6) == RPi File System DIST-UPGRADE$(tput sgr0)"
    sudo apt-get -q -y dist-upgrade
    if [ $? -ne 0 ] ; then
        echo "$scriptname: Failure DIST-UPGRADING file system packages"
    fi

    # Display how long this took
    echo "$(tput setaf 2) == System upgrade finished in $((SECONDS-begin_sec)) seconds$(tput sgr0)"

}

# ===== function is_temp_graph_installed

function is_temp_graph_installed() {
    # init to graph programs are installed
    graph_installed=0

    # Does user have a crontab?
    crontab -u $user -l > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        dbgecho "user: $user does NOT have a crontab"
	graph_installed=1
    else
        dbgecho "user: $user already has a crontab, checking for both cron jobs"
        crontab -l | grep --quiet -i "db_rpitempupdate.sh"
        if [ $? -ne 0 ] ; then
            graph_installed=1
        fi
        dbgecho "Crontab entery for temperature is $graph_installed"

        crontab -l | grep --quiet -i "db_rpicpuload_update.sh"
        if [ $? -ne 0 ] ; then
            graph_installed=1
        fi
        dbgecho "Crontab entery for CPU load is $graph_installed"
    fi
    return $graph_installed
}

# ===== function install temperature graph

function install_temperature_graph() {
    echo "$(tput setaf 6) === Check for previous RPi activity & temperature graph install$(tput sgr0)"

    is_temp_graph_installed
    if [ $? -ne 0 ] ; then
        echo
        echo "$(tput setaf 2) -- Install RPi activity & temperature graph$(tput sgr0)"

        cd
        cd dev/github/
	if [ -d rpi-temp-graph ] ; then
            echo -e "\n\t$(tput setaf 6)rpi-temp-graph already exists ... removing$(tput setaf 7)\n"
	    sudo rm -r rpi-temp-graph
	fi
        git clone https://github.com/n7nix/rpi-temp-graph
	if [ $? -ne 0 ] ; then
            echo -e "\n\t$(tput setaf 1)Failed to get rpi-temp-graph repository$(tput setaf 7)\n"
	    exit 1
	fi
	# Verify source directory was created
	if [ -d rpi-temp-graph ] ; then
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
	else
            echo -e "\n\t$(tput setaf 1)Repo directory (rpi-temp-graph) does not exist! ... exiting$(tput setaf 7)\n"
	fi

    else
        echo "$(tput setaf 2) RPi activity & temperature graph already installed$(tput sgr0)"
    fi

    ## ----- Verify temperature value is going into database
    # Display IP address to use to view graph

    eth_ip=$(ip -4 -o addr show dev eth0 | awk '!/^[0-9]*: ?lo|link\/ether/ {gsub("/", " "); print $2" "$4}')
    wifi_ip=$(ip -4 -o addr show dev wlan0 | awk '!/^[0-9]*: ?lo|link\/ether/ {gsub("/", " "); print $2" "$4}')

    if [ -z "$eth_ip" ] ; then
        eth_ip="none"
    fi

    if [ -z "$wifi_ip" ] ; then
        wifi_ip="none"
    fi

    echo
    echo "$(tput setaf 6) == Check IP address: lan: $eth_ip, wan: $wifi_ip$(tput sgr0)"

    # in a browser verify temperature graph
    # http://10.0.42.184/cgi-bin/rpitemp.cgi

    ## ----- Verify cpu & ambient temperature working

    echo
    echo "$(tput setaf 6) == Check temperature graph update in cron table$(tput sgr0)"
    crontab -l

    ambtemp=$(rpiamb_gettemp.sh)
    cputemp=$(rpicpu_gettemp.sh)
    CPULOAD=$(cat /proc/loadavg | cut -f2 -d ' ')
    echo
    echo "$(tput setaf 2)Temperatures: cpu: $cputemp, ambient: $ambtemp, cpu activity: $CPULOAD$(tput sgr0)"
}

# ===== Display program help info

usage () {
	(
	echo "Usage: $scriptname [-t][-h]"
        echo "    -t   Only install RPi temperature graph"
        echo "    -h   Display this message"
        echo
	) 1>&2
	exit 1
}

#
# ===== Main
#

# Be sure NOT running as root
if [[ $EUID == 0 ]] ; then
    echo "Do not run as root"
    exit 0
fi

# Verify UDRC device is enumerated
echo "$(tput setaf 6) == Verify UDRC/DRAWS sound card device$(tput sgr0)"
check_udrc
if [ $? -eq 1 ] ; then
    exit
fi

# ------ update local bin directory
# NOTE: n7nix repo gets updated with bin_refresh.sh
# ------ update n7nix repo

cd
cd n7nix/config
./bin_refresh.sh

# Check for any command line arguments
if (( $# != 0 )) ; then
    key="$1"
    case $key in
        -t)
	    echo
            echo "$(tput setaf 6) == Install temperature graph ONLY$(tput sgr0)"
            ## ----- Install temperature RRD graph
            install_temperature_graph
	    exit 0
	;;
        -h)
            usage
            exit 1
        ;;

        *)
            echo "Undefined argument: $key"
            usage
            exit 1
        ;;
    esac
fi


# ------ update system

# The following section updates kernel & packages

package_update_only
#package_upgrade_only


## ------ first config
# Verify if first config has already been done
# How many times has the app_config.sh core script been run?
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
CFG_FINISHED_MSG="core config script FINISHED"

runcnt=$(grep -c "$CFG_FINISHED_MSG" "$UDR_INSTALL_LOGFILE")
dbgecho "core_config.sh has been run $runcnt time(s)"

echo
echo "$(tput setaf 6) === Verify app_config core has been run$(tput sgr0)"

## ONLY do a config core once
if [ $runcnt -eq 0 ] ; then
    echo
    echo "$(tput setaf 6) === Running app_config core$(tput sgr0)"
    cd
    cd n7nix/config
    sudo ./app_config.sh core

    # reboot so new hostname takes effect
    echo
    echo "$(tput setaf 2) == First pass of initial config FINISHED, about to reboot $(tput sgr0)"
    echo "$(tput setaf 2) == If you run this script again it will install Winlink packet programs$(tput sgr0)"
    sudo shutdown -r now

else
    echo "$(tput setaf 2) app_config core has already been configured $runcnt time(s)$(tput sgr0)"
fi


portnum=0
# Set radio connected to DRAWS $portnum to use discriminator

## ------ Set alsa parameters
echo
echo "$(tput setaf 6) == Set port number: $portnum for radio to use discriminator receive$(tput sgr0)"
sudo sed -i -e "/\[port$portnum\]/,/\[/ s/^receive_out=.*/receive_out=disc/" $PORT_CFG_FILE

echo
echo "$(tput setaf 6) == Set ALSA parameters for radio: $radio$(tput sgr0)"
setalsa-${radio}.sh

## ------ Determine if AX.25 is already running

AX25_RUNNING=true
AX25_SERVICE_LIST="direwolf.service ax25dev.service ax25dev.path ax25-mheardd.service ax25d.service"

for service in `echo ${AX25_SERVICE_LIST}` ; do
    systemctl is-active --quiet $service
    if [ $? -ne 0 ] ; then
        AX25_RUNNING=false
	dbgecho "Service: $service NOT running"
    fi
done

if [ $AX25_RUNNING = "false" ] ; then
    # Do this in case some of the services are running
    ax25-stop

    ## ------ start AX.25 & direwolf
    echo
    echo "$(tput setaf 6) == Start AX25/direwolf stacks$(tput sgr0)"
    ax25-start
fi

echo
echo "$(tput setaf 6) == AX25/direwolf systemd service status$(tput sgr0)"
ax25-status

## ------ winlink config

echo
echo "$(tput setaf 6) === Config Winlink Programs$(tput sgr0)"

# ------ Dectect if winlink config has already been done
echo "$(tput setaf 6) == Check for required Winlink files ...$(tput sgr0)"
CONTINUE_FLAG=false

REQUIRED_PRGMS="wl2kax25 postfix dovecot mutt lighttpd"
for prog_name in `echo ${REQUIRED_PRGMS}` ; do
   type -P $prog_name &>/dev/null
   if [ $? -ne 0 ] ; then
      echo "$scriptname: $(tput setaf 1) Required Winlink program: $prog_name will be installed$(tput sgr0)"
      CONTINUE_FLAG=true
   fi
done

if ! $CONTINUE_FLAG ; then
    echo "$(tput setaf 2) The following programs have already been installed: $REQUIRED_PRGMS$(tput sgr0)"
else
    ## ------ install paclink-unix
    # Requires call sign, Winlink password, grid square, real name
    echo
    echo "$(tput setaf 6) == Setup paclink-unix, postfix & dovecot$(tput sgr0)"
    cd
    cd n7nix/config
    sudo ./app_config.sh plu
fi

## ------ Verify 9600 baud packet works
if [ 1 -eq 0 ] ; then
    echo
    echo "$(tput setaf 6) == Set up direwolf to 9600 baud packet$(tput sgr0)"
    speed_switch.sh -b 9600
    alsa-show.sh
    time wl2kax25 n7nix
fi

## ------ Winlink packet station config finished

## ----- Install temperature RRD graph
install_temperature_graph

# Add heart beat trigger to boot config
grep -i --quiet "act_led_trigger" /boot/config.txt
if [ $? -ne 0 ] ; then
    echo "dtparam=act_led_trigger=heartbeat" | sudo tee -a /boot/config.txt > /dev/null
fi
pi_leds.sh heartbeat
