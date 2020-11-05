#!/bin/bash
#
#  wd_status.sh

RSTS_REG=$(vcgencmd get_rsts)

REBOOT_CNT=$(last reboot | grep ^reboot | wc -l)

echo "RSTS: $RSTS_REG, reboot count: $REBOOT_CNT"

echo "SYS log"
grep -i watchdog /var/log/syslog