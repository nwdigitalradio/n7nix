#!/bin/bash
#
# Update DRAWS sensor configuration file if kernel supports latest
# driver
DEBUG=

# ===== function make_sensor_cfg
# Replace draws sensor configuration file

function make_sensor_cfg() {

    echo "DEBUG: calling make_sensor_cfg"

    if [ ! -z "$DEBUG" ] ; then
        echo
        echo "DEBUG: Would have replaced $sensor_fname file"
        echo
    else
        cat  > $sensor_fname <<EOF
chip "iio_hwmon-*"
   label in1 "+12V"
   label in2 " +5V"
   label in3 "User ADC 1"
   label in4 "User ADC 2"
   label in5 "User ADC Differential"
   compute in2 8*@, @/8
   compute in1 ((48.7/10)+1)*@, @/((48.7/10)+1)
EOF
    fi
}

# ===== function update_sensor_cfg

function update_sensor_cfg() {

    sensor_fname="/etc/sensors.d/draws"

    # Does DRAWS sensor file name exist?
    if [ ! -e "$sensor_fname" ] ; then
        make_sensor_cfg
    else
        # Check if proper sensor config file is already installed
        grep -i "iio_hwmon-" $sensor_fname > /dev/null 2>&1
        if [[ $? -eq 0 ]] ; then
            echo "Already have iio_hwmon config for draws sensors"
        else
            echo "Incorrect sensor config file found ... replacing."
            make_sensor_cfg
        fi
    fi
}

# ===== function check_sensor_cfg
# Look at Kernel version number and verify
# sensor config file is up-to-date
# If kern ver is >= 5.4 update sensor configuration file

function check_sensor_cfg() {

    kernver_1dig=$(uname -r | cut -d'.' -f1)
    kernver_2dig=$(uname -r | cut -d'.' -f2)
    if [[ $kernver_1dig -ge 5 ]] ; then
        if [[ $kernver_1dig -eq 5 ]] ; then
            if [[ $kernver_2dig -lt 4 ]] ; then
                echo "sensor config: NOT updated based on kernel ver $(uname -r)"
                return
            fi
        fi
        echo "sensor config: Checking based on kernel ver $(uname -r)"
        update_sensor_cfg
    else
        echo "sensor config: NOT updated based on kernel ver $(uname -r)"
    fi
    echo
    echo "FINISHED updating sensor config file"
}

# ===== main

# Don't be root
if [[ $EUID == 0 ]] ; then
   echo "Do NOT run this script as root"
   exit 1
fi

# Check if old sensor config file installed.
check_sensor_cfg
