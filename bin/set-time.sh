#!/bin/bash
#
# Automatically set correct time
# Requires an internet connection

# Set current time

# Check if ntp or chrony has been installed

echo "Before: $(date)"
program_name="ntp"
type -P "$program_name"  &>/dev/null
if [ $? -eq 0 ] ; then
    echo "Program: ${program_name} found"
    sudo service $program_name stop
    sudo ntpd -gq
    sudo service $program_name start
else
    program_name="chronyd"
    type -P "$program_name"  &>/dev/null
    if [ $? -eq 0 ] ; then
        echo "Daemon: ${program_name} found"
        sudo chronyc makestep
    else
        echo -e "\n\t$(tput setaf 1)Neither ntp nor chrony installed $(tput setaf 7)\n"
    fi
fi
echo "After: $(date)"
