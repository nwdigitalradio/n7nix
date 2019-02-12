#!/bin/bash
#
# Collect a bunch of information about ntp time condition

echo -e "\n\t$(tput setaf 4)timedatectl$(tput setaf 7)\n"
sudo timedatectl
echo -e "\n\t$(tput setaf 4)chronyc sources$(tput setaf 7)\n"
chronyc sources
echo -e "\n\t$(tput setaf 4)chronyc sourcestats$(tput setaf 7)\n"
chronyc sourcestats
echo -e "\n\t$(tput setaf 4)chronyc tracking$(tput setaf 7)\n"
chronyc tracking
echo -e "\n\t$(tput setaf 4)chronyc activity$(tput setaf 7)\n"
chronyc activity
echo -e "\n\t$(tput setaf 4)chronyd systemctl status$(tput setaf 7)\n"
systemctl --no-pager status chronyd
echo -e "\n\t$(tput setaf 4)gpsd systemctl status$(tput setaf 7)\n"
systemctl --no-pager status gpsd
gpsd -V
