## UDRC / DRAWS Raspberry Pi image


[Set up a Raspberry Pi micro SD Card](DRAWS_CONFIG_SDCARD.md)

* Boot the new microSD card

```
login: pi
passwd: digiberry
```

### Initial Configuration
* Run initcfg.sh script
```
cd
cd n7nix/config
./initcfg.sh
```
* **The above _initcfg.sh_ script completes by rebooting first time it is run**

* Upon logging in:
  * Verify DRAWS codec is still enumerated
  * Verify AX25/direwolf are running:
```
aplay -l
ax25-status
```
* Should see something similar to below:
```
$ aplay -l
**** List of PLAYBACK Hardware Devices ****
card 0: b1 [bcm2835 HDMI 1], device 0: bcm2835 HDMI 1 [bcm2835 HDMI 1]
  Subdevices: 3/4
  Subdevice #0: subdevice #0
  Subdevice #1: subdevice #1
  Subdevice #2: subdevice #2
  Subdevice #3: subdevice #3
card 1: Headphones [bcm2835 Headphones], device 0: bcm2835 Headphones [bcm2835 Headphones]
  Subdevices: 4/4
  Subdevice #0: subdevice #0
  Subdevice #1: subdevice #1
  Subdevice #2: subdevice #2
  Subdevice #3: subdevice #3
card 2: udrc [udrc], device 0: bcm2835-i2s-tlv320aic32x4-hifi tlv320aic32x4-hifi-0 [bcm2835-i2s-tlv320aic32x4-hifi tlv320aic32x4-hifi-0]
  Subdevices: 0/1
  Subdevice #0: subdevice #0
```
```
$ ax25-status
Status for direwolf.service: RUNNING and ENABLED
Status for ax25dev.service: RUNNING and ENABLED
Status for ax25dev.path: RUNNING and ENABLED
Status for ax25-mheardd.service: RUNNING and ENABLED
Status for ax25d.service: RUNNING and ENABLED
AX.25 device: ax0 successfully configured with ip: 192.168.0.2
AX.25 device: ax1 successfully configured with ip: 192.168.1.3
Direwolf is running with pid of 646
port: 0, speed: 1200, slottime: 200, txdelay: 500, t1 timeout: 3000, t2 timeout: 1000
port: 1, speed: 1200, slottime: 200, txdelay: 500, t1 timeout: 3000, t2 timeout: 1000
Device: ax0 exists, Device: ax1 exists
```

#### Packet Program Options
[Packet Options](DRAWS_CONFIG_PACKET.md)

#### HF Program Options
[HF  Options](DRAWS_CONFIG_HF.md)

### ----- Initial Configuration Completed -----
* The following are miscellaneous notes

#### To Disable the RPi On-Board Audio Device

* The default configuration enables the RPi on board bcm2835 sound device
* If for some reason you want to disable the sound device then:
  * As root comment the following line in _/boot/config.txt_
  * ie. put a hash (#) character at the beginning of the line.
```
dtparam=audio=on
```
* You need to reboot for any changes in _/boot/config.txt_ to take effect
* after a reboot verify by listing all the sound playback hardware devices:
```
aplay -l
```

#### Make your own Raspberry Pi image
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
* **As of Feb/2021 you must revert to kernel 5.4.79 and place a hold on kernel upgrades**

  * To verify your current kernel version
```
uname -a
```
* You should see: ```5.4.79-v7l```
* If you see : ```5.10.11-v7l``` then your DRAWS system will have problems
  * The problem occurs in clk_hw_create_clk
    * refcount_t: addition on 0; use-after-free
    * tlv320aic32x4 1-0018: Failed to get clk 'bdiv': -2
  * To revert your kernel back to 5.4.79-v7l+ run the following:
```
sudo rpi-update 0642816ed05d31fb37fc8fbbba9e1774b475113f
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
* Once you confirm that there is a hold on the Raspberry Pi kernel it is safe to upgrade other programs. ie. you can do the following:
```
sudo apt-get dist-upgrade
sudo apt full-upgrade
```
### To unhold ALL held packages
* Use the following command:
```
apt-mark unhold $(apt-mark showhold)
```

#### Historical Kernel Hold Info
##### Spring 2020 Kernel Hold
* Revert kernel 5.4.51 # back to 4.19.118-v7l+
* You should see: ```4.19.118-v7l+```
* If you see : ```5.4.51-v7l+``` then your DRAWS hat will have problems
  * The driver for the TI ads1015 chip is missing in this kernel.
  * To revert your kernel back to 4.19.118 run the following (courtesy of Thomas KF7RSF):
```
sudo rpi-upgrade e1050e94821a70b2e4c72b318d6c6c968552e9a2
```
##### Spring 2021 Kernel Hold
* Revert kernel 5.10.11-v7l+ #1399 SMP Thu Jan 28 12:09:48 GMT 2021
  * to kernel 5.4.79-v7l+ #1373 SMP Mon Nov 23 13:27:40

```
sudo rpi-update 0642816ed05d31fb37fc8fbbba9e1774b475113f
```