## DRAWS Raspberry Pi image

##### Download the image file

* [Go to the download site](http:nwdig.net/downloads) to find the current filename of the image
  * You can get the image using the following or just click on the filename using your browser.
```bash
wget http://nwdig.net/downloads/current_beta.zip
```

##### Unzip the image file
```bash
unzip current_beta.zip
```
##### Provision an SD card
* At least an 8GB microSD card is recommend

* If you need options for writing the image to the SD card ie. you are
not running Linux go to the [Raspberry Pi documentation
page](https://www.raspberrypi.org/documentation/installation/installing-images/)
and scroll down to **"Writing an image to the SD card"**
* For linux use the Department of Defense Computer Forensics Lab
(DCFL) version of dd.

```
time dcfldd if=current_beta.img of=/dev/sdf bs=4M
sync
```

* Boot the new microSD card

```
login: pi
passwd: nwcompass
```

##### Configure core functionality

* Whether you want **direwolf for packet functionality** or run **HF
apps** with the draws HAT do the following:

```bash
cd
cd n7nix/config
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

* **Now reboot your RPi** & [verify your installation is working
properly](https://github.com/nwdigitalradio/n7nix/blob/master/VERIFY_CONFIG.md)
* For those that do not care about packet please keep reading for an
appropriate way to unload direwolf & ax.25.


##### More program options

* After confirming that the core functionality works you can configure
other packet programs that will use direwolf such as rmsgw,
paclink-unix, etc:

```bash
./app_config.sh rmsgw
./app_config.sh plu
```

* If you want to run some other program that does NOT use direwolf like: jscall, wsjtx, fldigi, then do this:
```bash
cd
cd bin
sudo su
./ax25-stop
```
* This will bring down direwolf & all the ax.25 services allowing another program to use the DRAWS sound card.
* To stop direwolf & the AX.25 stack from running after a boot do this:

```bash
cd
cd bin
sudo su
./ax25-disable
```

##### enable RPi audio device

* uncomment the following line in _/boot/config.txt_
  * ie. remove the hash character from the beginning of the line.
```
dtparam=audio=on
```
* after a reboot verify the RPi sound device has been enumerated by
listing all the sound playback hardware devices:
```
aplay -l
```
* Look for a response that looks similar to this:
```
**** List of PLAYBACK Hardware Devices ****
card 0: ALSA [bcm2835 ALSA], device 0: bcm2835 ALSA [bcm2835 ALSA]
  Subdevices: 7/7
  Subdevice #0: subdevice #0
  Subdevice #1: subdevice #1
  Subdevice #2: subdevice #2
  Subdevice #3: subdevice #3
  Subdevice #4: subdevice #4
  Subdevice #5: subdevice #5
  Subdevice #6: subdevice #6
card 0: ALSA [bcm2835 ALSA], device 1: bcm2835 ALSA [bcm2835 IEC958/HDMI]
  Subdevices: 1/1
  Subdevice #0: subdevice #0
card 1: udrc [udrc], device 0: Universal Digital Radio Controller tlv320aic32x4-hifi-0 []
  Subdevices: 0/1
  Subdevice #0: subdevice #0
```
