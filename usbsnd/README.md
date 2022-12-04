# Notes for changing default soundcard from DRAWS to DINAH
### usb_set.sh command options
```
usb_set.sh Ver: 1.1
Usage: usb_set.sh [-D <device_name>][-h]
   -D <device type> | --device <device type>  Set device to either udr or dinah, default dinah
   -e               Edit config files
   -t               compare config files
   -s               show status/config
   -S <baud rate> | --speed <baud rate>  Set speed to 1200 or 9600 baud, default 1200
   -d | --debug     set debug flag
   -h               no arg, display this message
```
* Typical usage would be to check config status, _-s_ then edit config files with the edit option, _-e_

### Confile File Edit List

* List of config files edited
```
/usr/local/etc/ax25/port.conf
/usr/local/etc/ax25/ax25d.conf
/usr/local/etc/ax25/axports
/etc/direwolf.conf
```

### Verify DINAH (or DRAWS) sound card is enumerated
* Use ```arecord``` command:
```
arecord -l
```
* Output from this command will look like the following if BOTH a DRAWS card AND a DINAH USB sound device are installed.
```
**** List of CAPTURE Hardware Devices ****
card 2: Device [USB Audio Device], device 0: USB Audio [USB Audio]
  Subdevices: 1/1
  Subdevice #0: subdevice #0
card 3: udrc [udrc], device 0: bcm2835-i2s-tlv320aic32x4-hifi tlv320aic32x4-hifi-0 [bcm2835-i2s-tlv320aic32x4-hifi tlv320aic32x4-hifi-0]
  Subdevices: 1/1
  Subdevice #0: subdevice #0
```

### How to run usb_set.sh
* How to run script to set config files to use a DINAH USB sound device as the default sound card

* Verify there are no problems with current running installation
```
cd
cd n7nix/usbsnd

./usb_set.sh -s
ax25-status
```

* Run the _usb_set.sh_ script which will edit above mentioned config files:

* The following ```usb_set.sh``` command sets the baud rate to 9600 baud.
  * This should match the jumper plug 1 (JP1) settings on the [DINAH PCB](https://kitsforhams.com/wp-content/uploads/2022/10/DINAH-V4-Construction-Manual_v4.0.pdf)
```
cd
cd n7nix/usbsnd
./usb_set.sh -S 9600 -e
```

* Verify that the ALSA settings match required DINAH settings
```
setalsa-dinah.sh
```
* Output of ```setalsa-dinah.sh``` for DINAH connected to a Kenwood TM-v71a
```
Sat 03 Dec 2022 12:43:32 PM PST: Radio: Generic set from setalsa-dinah.sh
Speaker			L:-19.00dB	R:-19.00dB
Mic			-23.00dB
Auto Gain Control	off
```
* Restart AX.25 stack
```
ax25-status
ax25-stop
ax25-start
ax25-status
```

### Test the sound card switch with the following commands
* Send a beacon

```
cd
cd n7nix/debug
./beacmin.sh -D dinah
```

* Connect peer-to-peer with a Winlink station
```
wl2kax25 -a dinah0 -c <some winlink station call sign>
```
