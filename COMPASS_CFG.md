# compass kernel

## git a compass image

* Download a Compass Linux image from http://archive.compasslinux.org/images
  * The 'lite' version is without a GUI
  * The full version has the LXDE Windows Manager & a graphic configuration tools for other stuff.
* Unzip and copy the uncompressed image to the SD card using the procedure outlined on the [Raspberry Pi site](https://www.raspberrypi.org/documentation/installation/installing-images/)

## first boot
* Power up, find IP address assigned to this device
* Make sure you have an internet connection.

```bash
ping yahoo.com
sudo su
apt-get update
# Be patient, the following command will take some time
apt-get upgrade
apt-get install -y mg jed rsync build-essential autoconf automake libtool git libasound2-dev whois libncurses5-dev
# reboot
shutdown -r now
```
* relogin as same user

```bash
mkdir install
cd install
git clone https://github.com/nwdigitalradio/n7nix
cd n7nix/config
sudo su
./init_install.sh
```
* Now new RPi image has been initialized & AX.25 & direwolf are installed.
* Remaining to be done, each of the subsystems need to be configured.
