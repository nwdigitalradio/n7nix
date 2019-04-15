#!/bin/bash
#
# Add: WantedBy=multi-user.target
# To [Install] in: /lib/systemd/system/gpsd.service
# Also have to systemctl enable gpsd.service
#
# Uncomment this statement for debug echos
# DEBUG=1


scriptname="`basename $0`"
UDR_INSTALL_LOGFILE="/var/log/udr_install.log"

# Install files for the NW Digital Radio DRAWS HAT
# sudo apt-get install gpsd gpsd-clients python-gps pps-tools libgps-dev chrony
sudo apt-get install gpsd gpsd-clients python-gps pps-tools libgps-dev chrony

# Ended up have to build gpsd from source like this
# The following is from notes & not tested in a scrit

echo "Build gpsd from source"
#gpsd_ver="3.18.1"
gpsd_ver="$(curl -s http://download-mirror.savannah.gnu.org/releases/gpsd/?C=M | tail -n 2 | head -n 1 | cut -d'-' -f2 |cut -d '.' -f1,2,3)"

# Download tarball
wget http://download-mirror.savannah.gnu.org/releases/gpsd/gpsd-$gpsd_ver.tar.gz
tar -zxvf gpsd-$gpsd_ver.tar.gz
# get rid of version number in directory name
mv gpsd-$gpsd_ver gpsd
cd gpsd

# Clone git repo
# git clone https://git.savannah.gnu.org/git/gpsd.git
# cd gpsd

apt-get install scons
scons
sudo scons check
sudo scons udev-install

echo "Setup default gpsd file"

sudo  tee /etc/default/gpsd > /dev/null << EOT
# Configure gpsd
START_DAEMON="true"
DEVICES="/dev/ttySC0 /dev/pps0"
GPSD_OPTIONS="-n"
EOT

echo "Setup default chrony.conf file"

sudo tee /etc/chrony/chrony.conf > /dev/null << EOT
# Welcome to the chrony configuration file. See chrony.conf(5) for more
# information about usuable directives.
pool 2.debian.pool.ntp.org iburst

# initstepslew 30 2.debian.pool.ntp.org

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
rtcsync

# Step the system clock instead of slewing it if the adjustment is larger than
# one second, but only in the first three clock updates.
makestep 1 3

refclock SHM 0 refid GPS precision 1e-3 offset 0.5 delay 0.2 poll 3 trust
# SHM1 from gpsd (if present) is from the kernel PPS_LDISC module.
# It includes PPS and will be accurate to a few ns
# refclock SHM 1 offset 0.0 delay 0.1 refid PPS
refclock SHM 2 refid PPS precision 1e-9 poll 3 trust
# refclock PPS /dev/pps0 lock GPS trust prefer

# Configure broadcast and allow for your network and uncomment (Multiple declarations for each allowed)
#broadcast 30 192.168.255.255
#allow 192.168.0.0/16
#allow 44.0.0.0/8
EOT

systemctl unmask gpsd

systemctl enable gpsd
systemctl --no-pager start gpsd
systemctl enable chrony
systemctl --no-pager start chrony

echo "$(date "+%Y %m %d %T %Z"): $scriptname: gps install script FINISHED" | tee -a $UDR_INSTALL_LOGFILE
echo
