#!/bin/bash

systemctl stop ircnodedashboard
systemctl stop dstarconfig
systemctl disable ircnodedashboard
systemctl disable dstarconfig

echo "Dstar stopped"
