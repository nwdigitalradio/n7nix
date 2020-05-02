## How to Configure a DRAWS for 2 port operation

* This guide is for using both ports of the DRAWS hat to control 2 radios.
  * There are 3 sections for 3 different scenarios.
1. TWO ports for packet both using VHF/UHF Radios
1. TWO ports, 1 for VHF/UHF packet, 1 for HF programs
1. TWO ports, both for HF programs


### 1. TWO ports for packet using VHF/UHF Radio

* Determine the PCM, LO_DRIVER & ADC_LEVEL settings for particular radios being used.
* _Use alsamixer_ to determine alsa levels and manually setup left & right channels

__SAVE THOSE SETTINGS in _your custom script___
* run custom setalsa script created from instructions above.


* [Configure PORT file for two packet channels](#edit-port-configuration-file)

### 2. TWO ports, 1 for VHF/UHF packet, 1 for HF programs


#### Configure PORT file for split channel



### 3. TWO ports, both for HF programs

Run ```ax25-stop```


### Configure ALSA settings for a specific radio


* [Link to **How to Set deviation** document](https://github.com/nwdigitalradio/n7nix/tree/master/deviation)
* Each _alsamixer_ level setting for Left & Right channel can be controlled indepently from the keyboard as follows:

```
       [Q | W | E ]  -- turn UP [ left | both | right ]

       [Z | X | C ] -- turn DOWN [ left | both | right ]
```


* For setting deviation ie. those alsa controls that affect transmission focus on:
  * PCM
  * LO_DRIVER
* Depending on your radio:
  * 1200 baud packet choose IN2 10kOhm
  * 9600 baud packet choose IN1 10kOhm

* ALSA control affecting reception
  * ADC_LEVEL

#### Make a custom setalsa script

* This step technically isn't required but allows reliably setting up the alsa levels in the future
* Use the [setalsa-tmv71a.sh script](https://github.com/nwdigitalradio/n7nix/blob/master/bin/setalsa-tmv71a.sh) as an example.
  * Copy the _setalsa-tmv71a.sh script_ to use as a prototype for _setalsa-yourcustomscript.sh_
* Edit these variables in _your custom script_
```
PCM_LEFT="0.0"
PCM_RIGHT="0.0"
LO_DRIVER_LEFT="0.0"
LO_DRIVER_RIGHT="0.0"
ADC_LEVEL_LEFT="0.0"
ADC_LEVEL_RIGHT="0.0"
```

#### Edit port configuration file
* example _port.conf_ file.

```
 Configuration for each sound card port
# version: 1.1
#
# speed is the modulator baud rate and can be:
#     1200
#     9600
#     off (for split channel)
#
# receive_out (from radio) can be:
#     disc (for discriminator) or
#     audio (for preemphasis/deemphasis)
#
# You can run 1200 baud with receive signal from discriminator
# You can NOT run 9600 baud with receive signal from audio

[port0]
speed=9600
ip_address="192.168.255.2"
receive_out=disc

[port1]
speed=1200
ip_address="192.168.255.3"
receive_out=audio
```
