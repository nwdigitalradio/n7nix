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

* Download a Compass Linux image from http://archive.compasslinux.org/images
  * The 'lite' version is without a GUI
  * The full version has the LXDE Windows Manager & a graphic configuration tools for other stuff.
* Unzip and copy the uncompressed image to the SD card using the procedure outlined on the [Raspberry Pi site](https://www.raspberrypi.org/documentation/installation/installing-images/)
  * For example, see below:
    * **Note:** If you don't get the output device correct of=/dev/sdx you can ruin what ever you have installed on workstation hard drive
```bash
unzip image_2016_09-03-compass-lite.zip
dd if=2016-09-03-compass-lite.img of=/dev/sdc bs=4M
```

## first boot
* **Make sure Ethernet cable is plugged into a working network**
* Power up, find IP address assigned to this device
  * It can take several minutes to boot up on the initial boot because the file system is being expanded.
  * Be patient.
* ssh into your RPi and do the following:

```bash
sudo su
apt-get update
# Be patient, the following command will take some time
# Also you may get a (q to quit) prompt to continue after reading about sudoers
# list. Just hit 'q'
apt-get upgrade
# Just copy & paste the following line
apt-get install -y mg jed rsync build-essential autoconf automake libtool git libasound2-dev whois libncurses5-dev
# reboot
shutdown -r now
```
## after reboot
* relogin as same user (probably pi) and execute the following commands.

```bash
git clone https://github.com/nwdigitalradio/n7nix
cd n7nix/config
sudo su
./core_install.sh
```

* note: to change your user password as root
```bash
passwd username
```
* note: When changing time zone type first letter of location,
  * ie. (A)merica, (L)os Angeles
  * then use arrow keys to make selection
* **When any choices appear on terminal just hit return**
  * ie. for /etc/ax25/axports nrports & rsports
* When the script finishes & you see *Initial install script FINISHED* the new RPi image has been initialized and AX.25 & direwolf are installed.

## Configure direwolf

* What remains is the  configuration of ax25, direwolf & systemd.
* You will be required to supply the following:
  * Your callsign
  * SSID used for direwolf APRS (recommend 1)

## After CORE install

* Core provides APRS & AX.25 packet functionality so you can either
test & verify this functionality or continue on to install one of the
following.

  * [RMS Gateway](RMSGW_INSTALL.md)
  * [paclink-unix](PACLINK-UNIX_INSTALL.md)
  * [paclink-unix with IMAP server](PACLINK-UNIX-IMAP_INSTALL.md)

## Verifying CORE Install
### Testing direwolf & the UDRC

* Open a console to the pi and type:
```bash
tail -f /var/log/direwolf/direwolf.log
```
* Open another console window to the pi and type:
```bash
cd bin
./ax25-status
```
### Testing AX.25

* In a console type:
```bash
netstat --ax25
```
* You should see something like this:
```
Active AX.25 sockets
Dest       Source     Device  State        Vr/Vs    Send-Q  Recv-Q
*          N7NIX-10   ax0     LISTENING    000/000  0       0
*          N7NIX-2    ax0     LISTENING    000/000  0       0
```
* In another console type:
  * You need to run listen as root
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
VE7RYF-8   udr0      7   Thu Nov 10 14:04:20
VE7RYF     udr0      3   Thu Nov 10 14:03:01
VE7CRP-8   udr0      5   Thu Nov 10 14:01:59
VE7CRD-8   udr0      7   Thu Nov 10 14:00:45
VE7AVV-8   udr0      3   Thu Nov 10 14:00:12
VE7AVV     udr0      1   Thu Nov 10 14:00:12
VA7VOP     udr0      2   Thu Nov 10 13:59:56
VE7CRD     udr0      2   Thu Nov 10 13:59:37
VA7BLD-8   udr0      6   Thu Nov 10 13:59:28
VA7BLD     udr0      2   Thu Nov 10 13:59:27
VE7WOD-8   udr0      6   Thu Nov 10 13:58:33
VE7SOK-8   udr0      5   Thu Nov 10 13:57:42
VE7SOK     udr0      2   Thu Nov 10 13:57:41
VE7CRP     udr0      1   Thu Nov 10 13:51:59
PBBS       udr0      1   Thu Nov 10 13:38:33
VE7SPR-8   udr0      1   Thu Nov 10 13:38:23
VE7XPL-9   udr0     42   Thu Nov 10 13:29:57
WB4KGY-3   udr0      1   Thu Nov 10 13:29:52
N7NIX-3    udr0      2   Thu Nov 10 13:29:17
N7NIX-10   udr0    277   Thu Nov 10 13:26:56
N7NIX      udr0    184   Thu Nov 10 13:26:49
VE7GEL-10  udr0      1   Thu Nov 10 13:18:28
WA7EBH-15  udr0      4   Thu Nov 10 13:18:18
VA7MAS     udr0     13   Thu Nov 10 13:17:48
VE7WOL-9   udr0     26   Thu Nov 10 13:17:45
W7COA-9    udr0     30   Thu Nov 10 13:17:40
K7KCA-3    udr0      3   Thu Nov 10 13:17:33
VA7DRW-9   udr0      5   Thu Nov 10 13:17:29
VA7BUG-9   udr0      1   Thu Nov 10 13:16:47
VE7RYF-10  udr0      8   Thu Nov 10 13:16:18
```
