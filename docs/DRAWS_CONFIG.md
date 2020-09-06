## UDRC / DRAWS Raspberry Pi image

### Provision the micro SD Card

##### Download the image file

* [Go to the download site](http:nwdig.net/downloads) to find the current filename of the image
  * You can get the image using the following or just click on the filename using your browser.
```bash
wget http://images.nwdigitalradio.com/downloads/current_image.img.xz
```

##### Decompress the xz compressed image file
* Linux requires xz-utils package
* Windows requires WinZip, Easy 7-Zip or Windows Explorer, right click on file.
* Mac requires any of B1 Free Archiver, The Unarchiver, EZ 7z or 7zX

```bash
xz --decompress current_image.img.xz
```

##### Provision an SD card
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

* After decompressing current_image.img.xz file you will find an image file: current_image.img

```
# Become root
sudo su
apt-get install dcfldd

# Use name of decompressed file ie. current_image.img
time (dcfldd if=current_image.img of=/dev/sdf bs=4M status=progress; sync)
# Doesn't hurt to run sync twice
sync
```

* The reason I time the write is that every so often the write completes in
around 2 minutes and I know a *good* write should take around 11
minutes on my machine.

* Boot the new microSD card

```
login: pi
passwd: digiberry
```

### Initial Configuration

#### Initial Config Summary

- 1: First boot:
  - Verify that required drivers for the DRAWS codec are loaded.
  - Update the configuration scripts
  - Follow 'Welcome to Raspberry Pi' piwiz screens.
- 2: Second boot: run script: ```app_config.sh core```
- 3: Third boot: Set your ALSA config
- 4: For packet turn on Direwolf & AX.25

### 1. First boot

#### Check for required drivers first
* Open a console and type:
```
aplay -l
```
* You should see a line in the output that looks something like this:
```
card 0: udrc [udrc], device 0: bcm2835-i2s-tlv320aic32x4-hifi tlv320aic32x4-hifi-0 []
```

* If you do **NOT** see _udrc_ enumerated  **do NOT continue**
  * Until the UDRC/DRAWS drivers are loaded the configuration scripts will not succeed.
  * Run the ```showudrc.sh``` script and [post the console output to the UDRC groups.io forum](https://nw-digital-radio.groups.io/g/udrc/topics)

#### Initial Image Config

* If you are running with an attached monitor you should see the Raspbian 'Welcome to Raspberry Pi' piwiz splash screen
  * **DO NOT** run the piwiz splash screen yet

##### Update NWDR image configuration scripts
```
cd
cd n7nix
git pull
cd config
./bin_refresh.sh
```

* If you previously put a hold on kernel upgrades (July 2020) then remove the hold
  * Previous sensor driver problems have been fixed in this kernel:
    *  ```Linux raspberrypi 5.4.51-v7l+ #1333 #SMP Mon Aug 10 16:51:40```

```
sudo su
apt-mark unhold $(apt-mark showhold)
```

#### Update Raspberry Pi OS package information and their dependencies

```
sudo su
apt-get update
apt-get upgrade

# revert back to normal user
exit
```

* If you are running with an attached monitor you should see the Raspbian 'Welcome to Raspberry Pi' piwiz splash screen
  * Follow the screens as you would on any other Raspbian install.
  * When prompted to restart the RPi please do so.

### 2. Second boot

##### Configure core functionality

* Whether you want **direwolf for packet functionality** or run **HF
apps** with the draws HAT do the following:

```bash
cd
cd n7nix/config
# Become root
sudo su
./app_config.sh core
```

* The above script sets up the following:
  * iptables
  * RPi login password
  * RPi host name
  * mail host name
  * time zone
  * current time via chrony
  * AX.25
  * direwolf
  * systemd

### 3. Third boot

* **You must set your ALSA configuration** for your particular radio at this time
  * Also note which connector you are using as you can vary ALSA settings based on which channel you are using
    * On a DRAWS hat left connector is left channel
    * On a UDRC II hat mDin6 connector is right channel
  * You also must route the AFOUT, compensated receive signal or the DISC, discriminator  receive signal with ALSA settings.
  * Verify your ALSA settings by running ```alsa-show.sh```

*  [verify your installation is working properly](https://github.com/nwdigitalradio/n7nix/blob/master/docs/VERIFY_CONFIG.md)

* **NOTE:** the default core config leaves AX.25 & _direwolf_ **NOT running** & **NOT enabled**
  * The default config is to run HF applications like js8call, wsjtx
  and FLdigi
  * If you are **not** interested in packet and want to run an HF app then go ahead & do that now.

### 4. For Packet Turn on Direwolf & AX.25

  * If you want to run a **packet application** or run some tests on the
    DRAWS board that requires _direwolf_ then enable AX.25/direwolf like this:

```
cd ~/bin
# Become root
sudo su
./ax25-start
```

##### Reboot to enable packet

* Now reboot and verify by running:
```
ax25-status
ax25-status -d
```

#### More Packet Program Options

* After confirming that the core functionality works you can configure
other packet programs that will use _direwolf_ such as rmsgw,
paclink-unix, etc:

```bash
cd
cd n7nix/config
# Become root
sudo su
# If you want to run a Linux RMS Gateway
./app_config.sh rmsgw
# If you want to send & receive Winlink messages
./app_config.sh plu
```

#### For HAM apps that do **NOT** use _direwolf_

* If you previously ran a packet app and now want to run some other
program that does **NOT** use _direwolf_ like: js8call, wsjtx, FLdigi,
then do this:

```bash
cd
cd bin
# Become root
sudo su
./ax25-stop
```
* This will stop _direwolf_ & all the AX.25 services allowing another program to use the DRAWS sound card.

##### FLdigi

* Soundcard device
  * Configure->Config dialog->Soundcard->Devices
    * Click on PortAudio check box and deselect all others
```
capture: udrc: bcm2835-i2s-tlv320aic32x4-hifi-0
playback: udrc: bcm2835-i2s-tlv320aic32x4-hifi-0
```
* PTT
  * Configuration->Rig->GPIO
    * For left mDin6 connector
      * Select BCM 12, check box ```=1```
    * For right mDin6 connector
      * Select BCM 23, check box ```=1```

##### JS8CALL

* Soundcard device
  * File->Settings-Audio->Modulation Sound Card
```
Input:  plughw:CARD=udrc,DEV=0
Output: plughw:CARD=udrc,DEV=0
```
* PTT
  * The following allows JS8Call to execute an external script for controlling a rig's PTT:
    * File->Settings->Radio->Rig Options->Advanced->PTT Command
```
/home/pi/bin/ptt_ctrl.sh
```
* Script defaults to using left connector, to use right connector
```
/home/pi/bin/ptt_ctrl.sh -r
```

#### To Enable the RPi On-Board Audio Device

* The default configuration enables the RPi on board bcm2835 sound device
* If for some reason you want to disable the sound device then:
  * As root comment the following line in _/boot/config.txt_
  * ie. put a hash character at the beginning of the line.
```
dtparam=audio=on
```
* You need to reboot for any changes in _/boot/config.txt_ to take effect
* after a reboot verify by listing all the sound playback hardware devices:
```
aplay -l
```

### Make your own Raspberry Pi image
* The driver required by the NW Digital Radio is now in the main line Linux kernel (version 4.19.66)
* To make your own Raspberry Pi image
  * Download the lastest version of Raspbian [from here](https://www.raspberrypi.org/downloads/raspbian/)
    * Choose one of:
      * Raspbian Buster Lite
      * Raspbian Buster with desktop
      * desktop and recommended software
* Add the following lines to the bottom of /boot/config.txt
```
dtoverlay=
dtoverlay=draws,alsaname=udrc
force_turbo=1
```
* If you want to ssh into your device then add an ssh file to the _/boot_ directory
```
touch /boot/ssh
```

* Boot the new micro SD card.

### Placing A Hold On Kernel Upgrade
* **For reference only, the current Linux kernel is safe to use with DRAWS**

  * To verify your current kernel version
```
uname -a
```
* You should see: ```4.19.118-v7l+```
* If you see : ```5.4.51-v7l+``` then your DRAWS hat will have problems
  * The driver for the TI ads1015 chip is missing in this kernel.
  * To revert your kernel back to 4.19.118 run the following (courtesy of Thomas KF7RSF):
```
sudo rpi-upgrade e1050e94821a70b2e4c72b318d6c6c968552e9a2
```

* Do **NOT** use the following commands:
  * _apt-get dist-upgrade_
  * _apt full-upgrade_

#### Verify a hold is placed on kernel upgrades
* In a console run the following command:
```
apt-mark showhold
```
* should see this in console output
```
libraspberrypi-bin
libraspberrypi-dev
libraspberrypi-doc
libraspberrypi0
raspberrypi-bootloader
raspberrypi-kernel
raspberrypi-kernel-headers
```
* If you did not see the above console output then place a hold on kernel upgrades by executing the following 2 hold commands as root:
```
sudo su
apt-mark hold libraspberrypi-bin libraspberrypi-dev libraspberrypi-doc libraspberrypi0
apt-mark hold raspberrypi-bootloader raspberrypi-kernel raspberrypi-kernel-headers
```
* Once you confirm that there is a hold on the Raspberry Pi kernel it is safe to upgrade other programs.
