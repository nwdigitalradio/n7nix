# Notes for changing default soundcard from DRAWS to DINAH

### Verify DINAH sound card is enumerated
* Use ```arecord``` command
```
arecord -l
```
* Output from this command will look like the following if BOTH a DRAWS card AND a DINAH USB device are installed.
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
* How to run script to set sound card to USB device

* Verify there are no problems with current running installation
```
ax25-status
```

* Run the script witch will edit these files:
  * /usr/local/etc/ax25/port.conf
  * /usr/local/etc/ax25/ax25d.conf
  * /usr/local/etc/ax25/axports
  * /etc/direwolf.conf
* The following command sets the baud rate to 9600 baud.
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

### Test with the following commands
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
