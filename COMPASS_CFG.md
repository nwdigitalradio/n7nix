# compass kernel

## git a compass image

* Download a Compass Linux image from http://archive.compasslinux.org/images
  * The 'lite' version is without a GUI
  * The full version has the LXDE Windows Manager & a graphic configuration tools for other stuff.
* Unzip and copy the uncompressed image to the SD card using the procedure outlined on the [Raspberry Pi site](https://www.raspberrypi.org/documentation/installation/installing-images/)

## first boot
* Power up, find IP address assigned to this device
*
```bash
sudo su
apt-get update
apt-get upgrade
apt-get install -y mg jed rsync build-essential autoconf automake libtool git libasound2-dev whois libncurses5-dev
mkdir install
cd install
git
```
# Everything below has been put in config/init_install.sh
## Make compass usable

* first things to do

```bash
apt-get update
apt-get upgrade
apt-get install mg jed rsync
passwd
mg /etc/hosts
mg /etc/hostname
dpkg-reconfigure tzdata
```

* build tools

```bash
apt-get install build-essential autoconf automake libtool git libncurses5-dev
```

* Install ax.25 lib, tools & apps

```bash
cd usr/local/src/ax25
wget https://github.com/ve7fet/linuxax25/archive/master.zip
unzip master.zip

./updAX25.sh
# libraries are installed in /usr/local/lib
ldconfig
cd ax25tools
make installconf
```

* Add to bottom of /boot/config.txt

```
# enable udrc
dtoverlay=udrc
force_turbo=1

# Rotate lcd screen
lcd_rotate=2

#dtoverlay=udrc-boost-output
```

  * add this entry to /etc/modules - I think this is for add-on RTC

```
i2c-dev
ax25
```

  * enable ax25 module
```
insmod /lib/modules/$(uname -r)/kernel/net/ax25/ax25.ko
```
  * install direwolf

```bash
git clone https://www.github.com/wb2osz/direwolf
sudo apt-get install libasound2-dev
cd direwolf
make
sudo make install
make install-conf
# This failed
make install-rpi

cp /root/direwolf.conf /etc
```
