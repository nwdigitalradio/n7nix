# Linux RMS Gateway install for UDRC

## git a compass image

* Download a Compass Linux image from http://archive.compasslinux.org/images
  * The 'lite' version is without a GUI
  * The full version has the LXDE Windows Manager & a graphic configuration tools for other stuff.
* Unzip and copy the uncompressed image to the SD card using the procedure outlined on the [Raspberry Pi site](https://www.raspberrypi.org/documentation/installation/installing-images/)
  * For example, see below:
    * **Note:** If you don't get the output device correct of=/dev/sdx you can ruin your workstation hard drive
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
# Also you may get a prompt to continue after reading about sudoers
# list.
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
./init_install.sh
```

* note: to change your password as root
````bash
passwd username
```
* note: When changing time zone type first letter of location,
  * ie. (A)merica, (L)os Angeles
* **When any choices appear on terminal just hit return**
* When the script finishes & you see *Initial install script finished* the new RPi image has been initialized and AX.25 & direwolf are installed.

## Remaining to be completed

* What remains is the  install/config of each of the following subsystems.
  * ax25
  * direwolf
  * systemd
  * rmsgw
* Execute the following script.
```bash
./app_install.sh
```
* Currently you will have to input your call sign a number of times.
  * This is being worked on
* You will be prompted for a SSID for direwolf APRS whether you are using it or not.
  * **Do not use 10**, I recommend using 1
* When the script finishes & you see *app install script FINISHED* you are ready to test the RMS gateway
* Reboot your pi one more time login & verify the hostname changed
  * You should see your console prompt like this: pi@your_host_name:

## Testing direwolf & the UDRC

* Open a console to the pi and type:
```bash
tail -f /var/log/direwolf/direwolf.log
```
* Open another console window to the pi and type:
```bash
cd bin
./ax25-status
```
## Testing the RMS Gateway
* Get someone to connect to your callsign with SSID of 10 ie. your_callsign-10
