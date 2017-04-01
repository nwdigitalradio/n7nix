#!/bin/bash
echo "----- /proc/version"
cat /proc/version
echo "----- /etc/*version"
cat /etc/*version
echo "----- /etc/*release"
cat /etc/*release
echo "----- lsb_release"
lsb_release -a
echo "---- systemd"
hostnamectl
