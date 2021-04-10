## HF Configuration Options

* For HAM apps that do **NOT** use _direwolf_
  * [List of HF programs installed on image](IMAGE_README.md#hf)

* Verify direwolf is not running and attached to the DRAWS codec
  * Assume you will be running a program that does **NOT** use _direwolf_ like: js8call, wsjtx, FLdigi
  * Shut down AX.25/direwolf by doing the following:

```bash
ax25-stop
```
* This will stop _direwolf_ & all the AX.25 services allowing another program to use the DRAWS sound card.

#### FLdigi
##### Configuration
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

#### WSJT-X
##### Configuration

* Menu settings for soundcard
  * File->Settings->Audio->soundcard
```
Input:  plughw:CARD=udrc,DEV=0
Output: plughw:CARD=udrc,DEV=0
```

* Menu settings for Radio
  * File->Settings->Audio->Radio

```
Rig: Hamlib NET rigctl
PTT Method CAT
Mode Data/Pkt
```

* PTT
  * Below ```-m 3011``` is for an ICOM IC-706MkIIG
  * Determine rig number by running
```
rigctl-wsjtx -l
```
  * Open a console and start the HAMlib rig control daemon
    * -r is rig control device name
    * -s is the baud rate set for your rig control device
```
rigctld-wsjtx -m 3011  -r /dev/ttyUSB0 -s 19200 -P GPIO -p 12
```

#### JS8CALL
##### Configuration
* Set up HAMlib rig control same as WSJT-X (see above)
* Soundcard device
  * File->Settings-Audio->Modulation Sound Card
```
Input:  plughw:CARD=udrc,DEV=0
Output: plughw:CARD=udrc,DEV=0
```

* Menu settings for Radio
  * File->Settings->Radio

```
Rig: Hamlib NET rigctl
```
  * File->Settings->Radio->Rig Options
```
PTT Method: CAT
Mode: Data/Pkt
Transmit Audio Source: Rear/Data
```

* PTT
  * The following allows JS8Call to execute an external script for controlling a rig's PTT:
    * File->Settings->Radio->Rig Options->Advanced->PTT Command
```
/home/pi/bin/ptt_ctrl.sh -l %1
```
* Script defaults to using left connector, to use right connector
```
/home/pi/bin/ptt_ctrl.sh -r %1
```

#### ARDOP
* [Run Arim with ARDOP](https://github.com/nwdigitalradio/n7nix/blob/master/ardop/README.md)