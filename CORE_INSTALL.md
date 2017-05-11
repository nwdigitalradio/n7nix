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

#### 1. Install everything in one shot, then config what you want

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
sudo su
# Should be in _n7nix/config_ directory
./image_install.sh
```
* Upon completion you should see this on the console:
```
image install script FINISHED
```

##### After the Install, config core whatever else you want

* RMS Gateway & paclink-unix require the core install, so do that
first
  * core includes, direwowlf, ax25, systemd

```bash
./core_config.sh

# reboot the RPi
# test direwolf, ax25
```

* At this point direwolf is operational & if you are connected to the
data port on a radio you can [view incoming packets](https://github.com/nwdigitalradio/n7nix/blob/master/direwolf/README.md).

```
# If RMS Gateway is required then
./app_config.sh rmsgw
# test RMS Gateway

# If paclink-unix with mail server is required then
./app_config.sh pluimap
# test plu with imap

# If basic paclink-unix is required
./app_config.sh plu
# test basic plu

```


#### 2. Install a component, config a component, test a component

* For this method you would do the following steps:
  * install core, config core, test core
  * install RMS Gateway, config, test RMS Gateway
  * install paclink-unix, config, test paclink-unix

```bash
sudo su
./core_install.sh
./core_config.sh
# test direwolf, ax25

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

#### Core Configuration

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

## After CORE install

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

## Verifying CORE Install
### Testing direwolf & the UDRC
#### Monitor Receive packets from direwolf
* Connect a cable from your UDRC to your radio.
* Tune to an active digital frequency such as 2M APRS, 144.390 MHz
* Open a console to the pi and type:
```bash
tail -f /var/log/direwolf/direwolf.log
```
* Tune your radio to the 2M 1200 baud APRS frequency 144.390 or some frequency known to have packet traffic
  * You should now be able to see the packets decoded by direwolf

#### Check status of all AX.25 & direwolf processes started with systemd
* Open another console window to the pi and as user pi type:
```bash
cd ~/bin
./ax25-status
```

* In the same directory you can stop and start the entire ax.25/tnc
stack including direwolf with these commands:
  * Note you need to do this as root

```bash
sudo su
./ax25-stop
./ax25-start
```
#### Verify version of Raspberry Pi, UDRC,

* There are some other progams in the bin directory that confirm that the installation went well.
  * While in local bin directory as user pi
```bash
cd ~/bin
./piver.sh
./udrcver.sh
```

#### check ALSA soundcard enumeration
  * While in local bin directory as user pi
```bash
cd ~/bin
./sndcard.sh
```

### Testing AX.25

* In a console type:
```bash
netstat --ax25
```
* You should see a list of open listening sockets that looks something like this:
```
Active AX.25 sockets
Dest       Source     Device  State        Vr/Vs    Send-Q  Recv-Q
*          N7NIX-10   ax0     LISTENING    000/000  0       0
*          N7NIX-2    ax0     LISTENING    000/000  0       0
```
* In another console as root type:

```bash
sudo su
listen -at
```
* Over time you should see packets scrolling up the screen

* In a console type:
```bash
mheard
```
* You should see something like this:
```
Callsign  Port Packets   Last Heard
KG7HQ-15   udr0     72   Sat Apr  1 08:52:59
N7DKL-9    udr0      8   Sat Apr  1 08:52:46
W7COA-9    udr0     23   Sat Apr  1 08:52:28
BALDI      udr0      2   Sat Apr  1 08:52:18
WA7EBH-15  udr0      2   Sat Apr  1 08:52:13
VA7RKC-9   udr0      1   Sat Apr  1 08:52:06
VE7OLG-9   udr0      2   Sat Apr  1 08:51:53
VE7ZKI-8   udr0      3   Sat Apr  1 08:51:48
VA7MAS     udr0      6   Sat Apr  1 08:51:37
SEDRO      udr0      2   Sat Apr  1 08:51:35
VE7ZNS     udr0      1   Sat Apr  1 08:51:22
W7WEC-9    udr0      7   Sat Apr  1 08:51:19
SNOVAL     udr0      1   Sat Apr  1 08:50:58
VE7FAA-9   udr0      8   Sat Apr  1 08:50:37
WB4KGY-3   udr0      1   Sat Apr  1 08:49:36
VE7NV-1    udr0      1   Sat Apr  1 08:48:52
KF7VOP     udr0      1   Sat Apr  1 08:48:35
VA7HXD     udr0      1   Sat Apr  1 08:47:53
NG7W       udr0      3   Sat Apr  1 08:47:26
VE7MKF-3   udr0      3   Sat Apr  1 08:46:48
K7KCA-12   udr0     11   Sat Apr  1 08:46:19
LDYSMH     udr0      1   Sat Apr  1 08:46:00
DOGMTN     udr0      1   Sat Apr  1 08:45:44
VE7RVT-12  udr0      1   Sat Apr  1 08:44:36
VA7MP      udr0      1   Sat Apr  1 08:43:04
```
