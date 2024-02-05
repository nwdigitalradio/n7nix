#!/bin/bash
#
# Test script for checking if 'app_config.sh core' has been run
#
DEBUG=
VERSION="1.1"
scriptname="`basename $0`"

UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
cfg_script_name="app_config.sh core"
CFG_FINISHED_MSG="app_config.sh: core config script FINISHED"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function check_4_dinah
# Sets variable $DEVICE

function check_4_dinah() {

    DEVICE=
    #   echo "aplay command: "
    #   aplay -l
    aplay -l | grep -q -i "USB Audio Device"
    if [ "$?" -eq 0 ] ; then
        DEVICE="dinah"
    fi
}

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

# ===== function check_dtoverlay
#
# Verify the DT overlay file matches HAT product ID
# Requires variable prod_id to be set

function check_dtoverlay() {

    bootcfgfile="/boot/firmware/config.txt"
    if [ ! -e "$bootcfgfile" ] ; then
        bootcfgfile="/boot/config.txt"
    fi

    # Check for draws overlay
    grep "^dtoverlay=draws" $bootcfgfile > /dev/null
    retcode="$?"
    if [ $retcode = 0 ] ; then
        echo "dt overlay configured for a draws"
        if [ "$prod_id" = "0x0004" ] ; then
            echo "HAT product ID matches overlay"
        else
            echo "$(tput setaf 1)HAT product ID ($prod_id) does NOT match overlay $(tput sgr0)"
        fi
    else
        grep "^dtoverlay=udrc" $bootcfgfile > /dev/null
        retcode="$?"
        if [ $retcode = 0 ] ; then
            echo "dt overlay configured for a UDRC or UDRC II"
            if [ "$prod_id" = "0x0002" ] || [ "$prod_id" = "0x0003" ] ; then
                echo "HAT product ID matches overlay"
            else
                echo "$(tput setaf 1)HAT product ID ($prod_id) does NOT match overlay $(tput sgr0)"
            fi
        else
            echo "No dt overlay config found for DRAWS or UDRC"
        fi
    fi
}

# ===== function is_hostname
# Has hostname already been changed?

function is_hostname() {
    retcode=0
    # Check hostname
    HOSTNAME=$(cat /etc/hostname | tail -1)

    dbgecho " === Verify current hostname: $HOSTNAME"

    # Check for any of the default hostnames
    if [ "$HOSTNAME" = "raspberrypi" ] || [ "$HOSTNAME" = "compass" ] || [ "$HOSTNAME" = "draws" ] || [ -z "$HOSTNAME" ] ; then
        dbgecho "IS using default hostname $HOSTNAME"
        retcode=1
    else
        dbgecho "NOT using default hostname, using: $HOSTNAME"
    fi
    dbgecho "is_hostname ret: $retcode"
    ret_hostname=$retcode
    return $retcode
}

# ===== function is_password
# Has password already been changed?

function is_password() {

    retcode=0

    prog_name="mkpasswd"
    type -P $prog_name &>/dev/null
    mkpasswd_exists=$?

    if [ $mkpasswd_exists -eq 0 ] ; then
        # get salt
        SALT=$($GREPCMD pi /etc/shadow | awk -F\$ '{print $3}')

        PASSGEN_RASPBERRY=$(mkpasswd --method=sha-512 --salt=$SALT raspberry)
        PASSGEN_NWCOMPASS=$(mkpasswd --method=sha-512 --salt=$SALT nwcompass)
        PASSFILE=$($GREPCMD pi /etc/shadow | cut -d ':' -f2)

        dbgecho "SALT: $SALT"
        dbgecho "pass file: $PASSFILE"
        dbgecho "pass  gen raspberry: $PASSGEN_RASPBERRY"
        dbgecho "pass  gen nwcompass: $PASSGEN_NWCOMPASS"

        if [ "$PASSFILE" = "$PASSGEN_RASPBERRY" ] || [ "$PASSFILE" = "$PASSGEN_NWCOMPASS" ] ; then
            dbgecho "User pi IS using default password"
            retcode=1
        else
            dbgecho "User pi NOT using default password"
        fi
    else
        retcode=0
    fi
    dbgecho "is_password ret: $retcode"
    ret_password=$retcode
    return $retcode
}

# ===== function is_logappcfg
# Has there been a log file entry for app_config.sh core script?

function is_logappcfg() {
    retcode=1

    dbgecho " === Verify log file entry for app_config.sh core"
    if [ -e "$UDR_INSTALL_LOGFILE" ] ; then
        grep -i "$CFG_FINISHED_MSG" "$UDR_INSTALL_LOGFILE" > /dev/null 2>&1
        retcode="$?"
        if [ "$retcode" ] ; then
            dbgecho "Found log file entery for $CFG_FINISHED_MSG"
        else
            dbgecho "NO log file entery for $CFG_FINISHED_MSG"
        fi
    else
        echo "File: $UDR_INSTALL_LOGFILE does not exist"
    fi
    dbgecho "is_logappcfg ret: $retcode"

    initcfg_cnt=$(grep -i initcfg /var/log/udr_install.log | rev | cut -f2 -d' ' | tail -n 1)
    if [ -z "$initcfg_cnt" ] ; then
        echo "-- initcfg script has NOT been run"
    else
        echo "-- initcfg script has been run $initcfg_cnt time(s)."
    fi
    ret_logappcfg=$retcode
    return $retcode
}

# ===== main

echo "$scriptname: $VERSION"

if [[ $# -gt 0 ]] ; then
    DEBUG=1
fi

# Verify UDRC device is enumerated
echo "$(tput setaf 6) == Verify UDRC/DRAWS sound card device$(tput sgr0)"
check_udrc
if [ $? -eq 1 ] ; then
    echo "No sound card enumerated by kernel driver"
fi

# Check vendor name & HAT product id
prod_id=0
echo "== Device tree hat check:"
if [ -d "/proc/device-tree/hat" ] ; then

    dtree_vendorfile="/proc/device-tree/hat/vendor"
    vendor="$(tr -d '\0' < $dtree_vendorfile)"

    dtree_prodidfile="/proc/device-tree/hat/product_id"
    prod_id="$(tr -d '\0' < $dtree_prodidfile)"

    echo "Found an RPi hat from: $vendor, product id: $prod_id"
else
    echo "No RPi hat found"
fi

# Check for a DINAH USB sound device
check_4_dinah
if [ -z "$DEVICE" ] ; then
    echo "No DINAH USB sound device found"
else
    echo "Found DINAH USB device"
fi

# Check bootcfg file for correct DT overlay loaded
# Uses prod_id set from product_id file /proc/device-tree/hat
check_dtoverlay

GREPCMD="grep -i"

if [ ! -r /etc/shadow ] ; then
    # Need to elevate permissions
    GREPCMD="sudo grep -i"
fi

# Debian 11 and newer uses yescript instead of sha-512
# 6 = sha-512
# y = yescrypt

encrypt_type=$($GREPCMD "pi" /etc/shadow | cut -f2 -d '$')

dbgecho "DEBUG: encrypt_type: $encrypt_type"
if [ "$encrypt_type" = 6 ] ; then
    dbgecho " === Verify current password"

    if is_hostname && is_password && is_logappcfg ; then
        echo "-- $cfg_script_name script has ALREADY been run"
    else
        # This sets the return code for the other checks in case conditional failed on is_hostname
        is_password
        is_logappcfg
        echo "-- $cfg_script_name script has NOT been run: hostname: $ret_hostname, passwd: $ret_password, logfile: $ret_logappcfg"
    fi
else
    echo "Password file is using something other than sha-512 encryption, NO password check done"
    if is_hostname && is_logappcfg ; then
        echo "-- $cfg_script_name script has ALREADY been run"
    else
        # This sets the return code for the other checks in case conditional failed on is_hostname
        is_logappcfg
        echo "-- $cfg_script_name script has NOT been run: hostname: $ret_hostname, passwd: $ret_password, logfile: $ret_logappcfg"
    fi
fi
