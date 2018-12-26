#!/bin/bash
#
# Test script for checking if 'app_config.sh core' has been run
#
#DEBUG=1

UDR_INSTALL_LOGFILE="/var/log/udr_install.log"
cfg_script_name="app_config.sh core"
CFG_FINISHED_MSG="app_config.sh: core config script FINISHED"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

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
    GREPCMD="grep -i"

    dbgecho " === Verify current password"
    if [ ! -r /etc/shadow ] ; then
        # Need to elevate permissions
        GREPCMD="sudo grep -i"
    fi

    # get salt
    SALT=$(sudo grep -i pi /etc/shadow | awk -F\$ '{print $3}')

    PASSGEN_RASPBERRY=$(mkpasswd --method=sha-512 --salt=$SALT raspberry)
    PASSGEN_NWCOMPASS=$(mkpasswd --method=sha-512 --salt=$SALT nwcompass)
    PASSFILE=$($GREPCMD pi /etc/shadow | cut -d ':' -f2)

#   dbgecho "SALT: $SALT"
#   dbgecho "pass file: $PASSFILE"
#   dbgecho "pass  gen raspberry: $PASSGEN_RASPBERRY"
#   dbgecho "pass  gen nwcompass: $PASSGEN_NWCOMPASS"

    if [ "$PASSFILE" = "$PASSGEN_RASPBERRY" ] || [ "$PASSFILE" = "$PASSGEN_NWCOMPASS" ] ; then
        dbgecho "User pi IS using default password"
        retcode=1
    else
        dbgecho "User pi NOT using default password"
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
    ret_logappcfg=$retcode
    return $retcode
}

# ===== main

if is_hostname && is_password && is_logappcfg ; then
    echo "-- $cfg_script_name script has ALREADY been run"
else
    # This sets the return code for the other checks in case conditional failed on is_hostname
    is_password
    is_logappcfg
    echo "-- $cfg_script_name script has NOT been run: hostname: $ret_hostname, passwd: $ret_password, logfile: $ret_logappcfg"
fi
