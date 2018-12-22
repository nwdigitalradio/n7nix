#!/bin/bash
#
# Uncomment this statement for debug echos
# DEBUG=1

scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

# Install files for the NW Digital Radio DRAWS HAT
sudo apt-get install gpsd gpsd-clients python-gps pps-tools libgps-dev chrony

echo "Setup default gpsd file"

sudo  tee /etc/default/gpsd > /dev/null << EOT
# Configure gpsd
START_DAEMON="true"
USBAUTO="true"
DEVICES="/dev/ttySC0 /dev/pps0"
GPSD_OPTIONS="-n"
EOT

echo "Setup default chrony.conf file"

sudo tee /etc/chrony/chrony.conf > /dev/null << EOT
# Welcome to the chrony configuration file. See chrony.conf(5) for more
# information about usuable directives.
pool 2.debian.pool.ntp.org iburst

# This directive specify the location of the file containing ID/key pairs for
# NTP authentication.
keyfile /etc/chrony/chrony.keys

# This directive specify the file into which chronyd will store the rate
# information.
driftfile /var/lib/chrony/chrony.drift

# Uncomment the following line to turn logging on.
log  measurements statistics tracking

# Log files location.
logdir /var/log/chrony

# Stop bad estimates upsetting machine clock.
maxupdateskew 100.0

# This directive tells 'chronyd' to parse the 'adjtime' file to find out if the
# real-time clock keeps local time or UTC. It overrides the 'rtconutc' directive.
#hwclockfile /etc/adjtime

# This directive enables kernel synchronisation (every 11 minutes) of the
# real-time clock. Note that it can't be used along with the 'rtcfile' directive.
#rtcsync

# Step the system clock instead of slewing it if the adjustment is larger than
# one second, but only in the first three clock updates.
makestep 1 3

refclock SHM 0 refid GPS precision 1e-3 offset 0.5 delay 0.2 poll 3 trust require
refclock SHM 2 refid PPS precision 1e-9 poll 3 trust
# refclock PPS /dev/pps0 lock GPS trust prefer

# Configure broadcast and allow for your network and uncomment (Multiple declarations for each allowed)
#broadcast 30 192.168.255.255
#allow 192.168.0.0/16
#allow 44.0.0.0/8
EOT

systemctl enable gpsd
systemctl start gpsd
systemctl enable chrony
systemctl start chrony

echo "$(date "+%Y %m %d %T %Z"): $scriptname: gps install script FINISHED" | tee -a $UDR_INSTALL_LOGFILE
echo
