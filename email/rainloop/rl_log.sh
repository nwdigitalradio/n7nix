#!/bin/bash
#
# Display current rainloop log file in a console

today=$(date "+%Y-%m-%d")
tail -f /var/www/rainloop/data/_data_/_default_/logs/log-$today.txt
