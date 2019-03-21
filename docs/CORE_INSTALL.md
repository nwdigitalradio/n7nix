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

## git a compass image

* Compass is a file system image for the Raspberry Pi that contains a kernel with the driver for the Texas Instruments tlv320aic32x4 Codec module.
* The NW Digital Radio UDRC II is a [hat](https://github.com/raspberrypi/hats) that contains this codec plus routes GPIO pins to control PTT.

* Download a Compass Linux image from http://archive.compasslinux.org/images
  * The 'lite' version is without a GUI
  * The full version has the LXDE Windows Manager & a graphic configuration tools for other stuff.
* Unzip and copy the uncompressed image to the SD card using the procedure outlined on the [Raspberry Pi site](https://www.raspberrypi.org/documentation/installation/installing-images/)
  * For example, see below:
    * **Note:** If you don't get the output device correct of=/dev/sdx you can ruin what ever you have installed on workstation hard drive
    * Below is an example only, the dates on the files will change.

```bash
unzip image-2016_05-23-compass-lite.zip
dd if=2016-05-23-compass-lite.img of=/dev/sdc bs=4M
```

* To enable ssh on first boot mount flash drive & create ssh file in /boot partition
  * On debian systems this partition may get auto mounted on /media/`<user_name>`/boot
```bash
touch /media/<user_name>/boot/ssh
```
* Another way to enable ssh by creating ssh file in boot partition by manually mounting boot partition
  * The x in sdx1 is a letter you must accuartely determine
```
mount /dev/sdx1 /media/sd
# Verify that you have in fact mounted the boot partition
touch /media/sd/ssh
umount /media/sd
```

## first boot
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
* You are logging in as user __pi__, with password __raspberry__

* and do the following:

```bash
# Become root
sudo su
apt-get update
# Be patient, the following command will take some time
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

#### 1. Install both RMS Gateway & paclink-unix in one shot, then config what you want

* This method is used to install a number of programs where the
Internet access is good and then do the config **without** requiring an
Internet connection.
  * Advantages:
    * Can run mostly unattended ie. just 2 prompts
      * The prompts are for configuring _iptables-persistent_ for
      saving current IPv4 & IPv6 rules.
        * Just hit return with **Yes** (default) selected
    * Can be used to build a known good image
  * This was the way the SeaPac workshop image was created

```bash
# Become root
sudo su
# Execute from n7nix/config directory
./image_install.sh
```
* Upon completion you should see this on the console:
```
image install script FINISHED
```

##### After Core Install, config core & then whatever else you want

* Both RMS Gateway & paclink-unix require the core install, so do that
first
  * core includes, direwowlf, ax25, systemd

```bash
# Become root
sudo su
# Execute from n7nix/config directory
./app_config.sh core
```
###### See **Core Configuration** below

**NOTE:** After ./app_config.sh core you must reboot

##### Now configure RMS Gateway or paclink-unix

After Core packages are configure, you can config RMS Gateway or paclink-unix

```
cd n7nix/config
# Become root
sudo su

# If RMS Gateway is required then
./app_config.sh rmsgw
# test RMS Gateway

# If basic paclink-unix is required
./app_config.sh plu
# test basic plu

# If paclink-unix with mail server is required then
./app_config.sh pluimap
# test plu with imap

```

### Alternate Install /  Config method
#### 2. Install a component, config a component, test a component

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


###### See **Core Configuration** below

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

* You will probably be asked to change your password
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

* Now reboot the RPi and test direwolf, ax25 for functionality

* At this point direwolf & AX.25 is operational & if you are connected to the
data port on a radio you can [view incoming packets](https://github.com/nwdigitalradio/n7nix/blob/master/direwolf/README.md).


## After CORE configuration

* Core provides APRS & AX.25 packet functionality so you can either
test & verify this functionality or continue on to install one of the
following.

  * [RMS Gateway](./rmsgw/README.md)
  * [paclink-unix](./plu/PACLINK-UNIX_INSTALL.md)
  * [paclink-unix with IMAP server](./plu/PACLINK-UNIX-IMAP_INSTALL.md)

### How to Enable Serial console

* To Enable a serial console on a Raspberry Pi 3 change 2 files
  * Disable bluetooth in /boot/config.txt
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
