# CORE Functionality Install for UDRC

## Components of CORE

* direwolf
* AX.25 lib tools & apps
* systemd transactional files

## Functionality of CORE

* After CORE components are installed the following functionality is enabled
  * APRS
  * AX.25 packet spy
  * mheard

# Installing CORE functionality

## Get a raspbian image

* Raspbian is a file system image for the Raspberry Pi that contains a kernel with the driver for the Texas Instruments tlv320aic32x4 Codec module.
* The NW Digital Radio UDRC, UDRC II & DRAWS are [hats](https://github.com/raspberrypi/hats) that contains this codec plus routes GPIO pins to control PTT.

* Download a Raspbian image from [here](https://www.raspberrypi.org/downloads/raspbian/)
  * The 'lite' version is without a GUI
  * The 'desktop' version has the LXDE Windows Manager & a graphic configuration tools for other stuff.
## Provision an SD Card

* At least a 16GB microSD card is recommended

* If you need options for writing the image to the SD card ie. you are
not running Linux go to the [Raspberry Pi documentation
page](https://www.raspberrypi.org/documentation/installation/installing-images/)
and scroll down to **"Writing an image to the SD card"**
* **For linux, use the Department of Defense Computer Forensics Lab
(DCFL) version of dd, _dcfldd_**.
  * **You can ruin** the drive on the machine you are using if you do not
  get the output device (of=) correct. ie. below _/dev/sdf_ is just an
  example.
  * There are good notes [here for Discovering the SD card mount
  point](https://www.raspberrypi.org/documentation/installation/installing-images/linux.md)

* To enable ssh on first boot, useful if you are using an image without a Window Manager, mount flash drive & create ssh file in /boot partition
  * On Debian systems this partition may get auto mounted on /media/`<user_name>`/boot
```bash
touch /media/<user_name>/boot/ssh
```
* Another way using a Linux system to enable ssh is by creating ssh file in boot partition by manually mounting boot partition
  * **Note:** the x in sdx1 below is a letter you must accuartely determine
```
mount /dev/sdx1 /media/sd
# Verify that you have in fact mounted the boot partition
touch /media/sd/ssh
umount /media/sd
```
#### After editing _/boot/config.txt_, test for a successful driver load
* For a DRAWS hat add the following lines to the bottom of
_/boot/config.txt_
```
dtoverlay=
dtoverlay=draws,alsaname=udrc
force_turbo=1
```

* For a UDRC/UDRC II hat add the following lines to the bottom of
_/boot/config.txt_
```
dtoverlay=
dtoverlay=udrc
force_turbo=1
```
* Reboot & test for a successful driver load
```
aplay -l
```
* You should see something like this which indicates the driver has enumerated the UDRC/UDRC II/DRAWS device.
```
card 1: udrc [udrc], device 0: bcm2835-i2s-tlv320aic32x4-hifi tlv320aic32x4-hifi-0 []
  Subdevices: 0/1
  Subdevice #0: subdevice #0
```

* If you do not see _udrc_ enumerated  **do not continue**

## ssh into your new image

* **Make sure Ethernet cable is plugged into a working network**
* Power up, find IP address assigned to this device
  * It can take several minutes to boot up on the initial boot because the file system is being expanded.
  * Be patient.

#### Note if you get this message on your host machine
```
$ ssh pi@<rpi_ip_address>
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
```
* go into your workstation .ssh directory, remove the known_hosts file & try again
```bash
cd .ssh
rm known_hosts
```
* Now ssh into your RPi ...
```bash
ssh pi@<rpi_ip_address>
```

* You are logging in as user __pi__, with password __raspberry__ and do the following:
* If you have an attached monitor run through the piwiz screens then do the following:

```bash
# Become root
sudo su
apt-get update
# Be patient, the following command may take some time
# Also you may get a (q to quit) prompt to continue after reading about sudoers
# list. Just hit 'q'
apt-get upgrade -y
apt-get install git
# reboot
shutdown -r now
```
## after reboot

* relogin as same user (probably pi), get the install script repo and start the install.
  * There are different scripts for program installation & program configuration.
  * The install scripts should run unattended, where as the configuration script will prompt you for pertinent things

#### Get the install script repo

```bash
git clone https://github.com/nwdigitalradio/n7nix
cd n7nix/config
```

### Two ways to do the install
### 1. Install everything in one shot, then config what you want

* This method is used to install a number of programs ([See IMAGE_README.md](https://github.com/nwdigitalradio/n7nix/blob/master/docs/IMAGE_README.md)) where the
Internet access is good and then do the config **without** requiring an Internet connection.

  * Advantages:
    * Can run mostly unattended ie. just 2 prompts
      * The prompts are for configuring _iptables-persistent_ for
      saving current IPv4 & IPv6 rules.
        * Just hit return with **Yes** (default) selected
    * Can be used to build a known good image
  * This is how the NWDR images are created.

```bash
# Save all console output
cd
script
# Go to install script directory
cd n7nix/config

# Become root
sudo su
# Execute from n7nix/config directory
./image_install.sh
```
* Upon completion you should see this on the console:
```
image install script FINISHED
```
* Now close out the [_script_](http://man7.org/linux/man-pages/man1/script.1.html) file by typing _exit_ twice.
```
# Exit su
exit
# Exit script program to close typescript file
# The typescript file contains all the console output,
#  useful for debugging.
exit
```
#### At this point everything in the image has been installed.
* now **reboot**

##### After Image Install, config core & then whatever else you want

* The configuration of the image at this point will be the same as
descibed in [DRAWS
CONFIG](https://github.com/nwdigitalradio/n7nix/blob/master/docs/DRAWS_CONFIG.md#initial-configuration)

* Most of the packet programs require the core configuration, so do that first
  * core includes, direwowlf, ax25, systemd, iptables

```bash
# Become root
sudo su
# Execute from n7nix/config directory
./app_config.sh core
```
* **You must set your ALSA configuration** for your particular radio
at this time

* **NOTE:** the default core config leaves AX.25 & _direwolf_ **NOT
running** & **NOT enabled**
* Please refer to [DRAWS
CONFIG](https://github.com/nwdigitalradio/n7nix/blob/master/docs/DRAWS_CONFIG.md#initial-configuration)
for more information.


###### See [**Core Configuration**](#core-configuration) below

**NOTE:** After ./app_config.sh core **you must reboot**

##### Now configure what you want ie. RMS Gateway or paclink-unix

After Core packages are configure, you can config RMS Gateway or paclink-unix

```
cd n7nix/config
# Become root
sudo su

# If RMS Gateway is required then
./app_config.sh rmsgw
# test RMS Gateway

# If paclink-unix is required
# Note this installs an IMAP server and email clients claws-mail & rainlooop
./app_config.sh plu
# test basic plu
```

### 2. Alternate Install /  Config method
#### Install a component, config a component, test a component

* For this method you would do the following steps:
  * Always install/config core first
    * install core, config core, test core
* **If** you want RMS Gateway functionality
  * install RMS Gateway, config, test RMS Gateway
* **If** you want Winlink client functionality
  * install paclink-unix, config, test paclink-unix

```bash
cd n7nix/config
# Become root
sudo su
./core_install.sh
./app_config.sh core
```
* now **reboot** & test direwolf, ax25
  * see below: **Testing direwolf & the UDRC**


###### See [**Core Configuration**](#core-configuration) below

```bash
# If RMS Gateway is required then
./app_install.sh rmsgw
./app_config.sh rmsgw
# test RMS Gateway

# If basic paclink-unix is required
./app_install.sh plu
./app_config.sh plu
# test basic plu

# If paclink-unix with mail server is required then
./app_install.sh pluimap
./app_config.sh pluimap
# test plu with imap

```
## Core Configuration

* Configuring core does not take long
  * Be sure to reboot after

* You may be asked to change your password
* You will be prompted to change hostname & set your time zone.
* note: When changing time zone type first letter of location,
  * ie. (A)merica, (L)os Angeles
  * then use arrow keys to make selection
* Part of core install is configuration of ax25, direwolf & systemd.
* You will be required to supply the following:
  * Your callsign
  * SSID used for direwolf APRS (recommend 1)
* When the script finishes you should see:

```
core configuration FINISHED

app install (core) script FINISHED
```

Now the RPi image has been initialized and AX.25 & direwolf are
installed.

* **reboot again**
```bash
# reboot
shutdown -r now
```

* If you want packet functionality start AX.25 & direwolf the following way:
* If you want to run some HF app the do **NOT** do this:
```
cd ~/bin
# Become root
sudo su
./ax25-start
```

* Now reboot the RPi and test direwolf, ax25 for functionality

* At this point direwolf & AX.25 is operational & if you are connected to the
data port on a radio you can [view incoming packets](https://github.com/nwdigitalradio/n7nix/blob/master/direwolf/README.md).


## After CORE configuration

* Core provides APRS & AX.25 packet functionality so you can either
test & verify this functionality or continue on to install one of the
following.

  * [RMS Gateway](https://github.com/nwdigitalradio/n7nix/blob/master/rmsgw/README.md)
  * [paclink-unix]((https://github.com/nwdigitalradio/n7nix/blob/master/plu/PACLINK-UNIX_INSTALL.md)
  * [paclink-unix with IMAP server](https://github.com/nwdigitalradio/n7nix/blob/master/plu/PACLINK-UNIX-IMAP_INSTALL.md)

### How to Enable Serial console

* To Enable a serial console on a Raspberry Pi 3 change 2 files
  * Disable bluetooth in _/boot/config.txt_
```
dtoverlay=pi3-disable-bt
```
  * Specify serial console port in _/boot/cmdline.txt_
    * Change console=serial0 to console=ttyAMA0,115200
    * For example:
```
dwc_otg.lpm_enable=0 console=ttyAMA0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait
```

## Verifying CORE Install/Config
* [Testing your install & config](https://github.com/nwdigitalradio/n7nix/blob/master/docs/VERIFY_CONFIG.md)
