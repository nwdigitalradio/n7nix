#!/bin/bash
#
#  wd_status.sh

# ===== function display_service_status
function display_service_status() {
    service="$1"
    if systemctl is-enabled --quiet "$service" ; then
        enabled_str="enabled"
    else
        enabled_str="NOT enabled"
    fi

    if systemctl is-active --quiet "$service" ; then
        active_str="running"
    else
        active_str="NOT running"
    fi
    echo "Service: $service is $enabled_str and $active_str"
}


# ===== main

display_service_status watchdog
RSTS_REG=$(vcgencmd get_rsts)

REBOOT_CNT=$(last reboot | grep ^reboot | wc -l)

echo "=== RSTS: $RSTS_REG, reboot count: $REBOOT_CNT"

echo "=== SYS log"
grep -i watchdog /var/log/syslog