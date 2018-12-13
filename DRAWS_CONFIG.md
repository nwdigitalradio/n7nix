## DRAWS Raspberry Pi image

###### Download the image file

* [Go to the download site](http://nwdig.net/downloads/) to find the current filename of the image
```bash
wget http://nwdig.net/downloads/<draws_download_file_name>
```

###### Unzip the image file
```bash
unzip <draws_image_download_file_name>
```
###### Provision an SD card
* We recommend at least an 8GB microSD card
```
time dcfldd if=<draws_image_download_file_name> of=/dev/sdf bs=4M
```

* Boot the new microSD card

###### Configure core functionality

* If you want direwolf functionality with the draws hat do this:

```bash
cd
cd n7nix/config
sudo su
./app_config.sh core
```

* This will run a script that sets up AX.25, direwolf & systemd

* Now reboot your RPi & [verify your installation is working properly](https://github.com/nwdigitalradio/n7nix/blob/master/VERIFY_CONFIG.md)


###### Test Receive

* Tune your radio to the 1200 baud APRS frequency: 144.39 because there should be lots of traffic there.

```bash
tail -f /var/log/direwolf/direwolf.log
```

* or open another console window

```bash
sudo su
listen -at
```
###### Test Transmit

* Tune your radio to the 1200 baud APRS frequency: 144.39
```bash
cd
cd n7nix/debug
sudo su
./btest.sh -P [udr0|udr1]
```

* This will send either a position beacon or a message beacon
with the -p or -m options.

* Using a browser go to: [aprs.fi](https://aprs.fi/)
  * Under Other Views, click on raw packets
  * Put your call sign followed by an asterisk in "Originating callsign"
  * Click search, you should see the beacon you just transmitted.

###### More program options

* After confirming that the core functionality works you can configure rmsgw, paclink-unix or someother packet
program that requires direwolf ie.:

```bash
./app_config.sh rmsgw
./app_config.sh plu
```

* If you want to run some other program that does NOT use direwolf then do this:
```bash
cd
cd bin
sudo su
./ax25-stop
```
* This will bring down direwolf & all the ax.25 services allowing another program to use the DRAWS sound card.