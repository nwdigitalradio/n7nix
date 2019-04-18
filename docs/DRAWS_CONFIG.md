## DRAWS Raspberry Pi image

### Provision the micro SD Card

##### Download the image file

* [Go to the download site](http:nwdig.net/downloads) to find the current filename of the image
  * You can get the image using the following or just click on the filename using your browser.
```bash
wget http://images.nwdigitalradio.com/downloads/current_beta.zip
```

##### Unzip the image file
```bash
unzip current_beta.zip
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

```
unzip current_beta.zip
# You will find an image file: draws_betaxx.img

# Become root
sudo su
apt-get install dcfldd

# Use name of unzipped file ie. draws_beta10.img
time (dcfldd if=draws_betaxx.img of=/dev/sdf bs=4M status=progress; sync)
# Doesn't hurt to run sync twice
sync
```

* The reason I time the write is that every so often the write completes in
around 2 minutes and I know a *good* write should take around 11
minutes on my machine.

* Boot the new microSD card

```
login: pi
passwd: nwcompass
```

### Initial Configuration

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

##### First Reboot After Initial Configuration

* **Now reboot your RPi** & [verify your installation is working
properly](https://github.com/nwdigitalradio/n7nix/blob/master/docs/VERIFY_CONFIG.md)
* **NOTE:** the default core config leaves AX.25 & _direwolf_ **NOT
running** & **NOT enabled**
  * The default config is to run HF applications like js8call, wsjtx
  and FLdigi
  * If you are **not** interested in packet and want to run an HF app then go ahead & do that now.
  * If you want to run a **packet application** or run some tests on the
  DRAWS board that requires _direwolf_ then enable AX.25/direwolf like this:
```
cd ~/bin
# Become root
sudo su
./ax25-start
```

##### Second Reboot to enable packet

* Now reboot and verify by running:
```
ax25-status
ax25-status -d
```

##### More Packet Program Options

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

#### To Enable the RPi on board audio device

* As root uncomment the following line in _/boot/config.txt_
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
