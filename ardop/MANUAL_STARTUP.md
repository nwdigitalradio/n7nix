## Manually start ARDOP processes in separate consoles

* Before you start be sure [Direwolf is not running](#stop-direwolf) (unless you are using split channel)

### Consoles

#### Console 1: Rig control

* Technically you do __NOT__ need _rigctrld_ running if you set radio frequency manually.
* Get rig control running first (only used by PAT at this time)

* [PAT Rig Control](https://github.com/la5nta/pat/wiki/Rig-control) wiki.
* Edit PAT config file: config.json
  * Add an entry to _hamlib_rigs_
  * ie. For an IC-706MKIIG
```
 "IC-706MKIIG": {"address": "localhost:4532", "network": "tcp"}
```
  * Edit "ardop": entry by adding a __rigctl rig name__
    * Link to [Hamlib rigctl rig names](https://github.com/Hamlib/Hamlib/wiki/Supported-Radios).
    * Must match a name from ```rigctl -l``` list
```
  "rig": "IC-706MKIIG",
```

* Start rig control daemon in another console
  * Note: _-s_ is the baud rate expected on the radio
    * This value can be configured in the radio
    * Found:
      * 4800 baud works on Icom IC-706mkIIG
      * 19200 baud works on Icom IC-7300 (need to confirm)
```
rigctld -m311 -r /dev/ttyUSB0 -s 4800
```
* The -m option above must match your radio
```
  -m, --model=ID                select radio model number. See model list
```
* For example to find the radio model number for the ic-706
```
rigctl -l | grep -i "706"
   309  Icom                   IC-706                  0.8.1           Untested
   310  Icom                   IC-706MkII              0.8.1           Untested
   311  Icom                   IC-706MkIIG             0.8.2           Stable
```

#### Console 2: ARDOP

* From your local bin directory start ARDOP
  * The following is for a DRAWS hat

* __Assuming only RPi internal sound device is installed__
* __For a DRAWS hat__ left mDin6 connector
```
cd ~/bin
./piardopc 8515 plughw:1,0 plughw:1,0 -p GPIO=12

# If .asoundrc is configured then
./piardopc 8515 pcm.ARDOP pcm.ARDOP -p GPIO=12
```
* __For a UDRC II hat__ left mDin6 connector
```
./piardopc 8515 plughw:1,0 plughw:1,0 -p GPIO=23

# If .asoundrc is configured then
./piardopc 8515 pcm.ARDOP pcm.ARDOP -p GPIO=23
```

#### Console 3: ARDOP listener
##### Console listener
*
```
pat --listen="ardop" interactive
```
##### HTML web server listener
*  control the active listeners with the --listen, -l option:
```
pat --listen winmor,ardop,ax25,telnet http
```
```
pat --listen="ardop" html
```


#### run piARDOP_GUI
* set Host Name: localhost
* set Port: 8515

#### Run arim
* Refer to this link for help: [Arim v2.8 Help](https://www.whitemesa.net/arim/arim.html)
* Open another console terminal window
* Run arim from home directory
  * This will create an arim.ini file in directory _arim_
* Exit arim (type q) and edit arim config file: _arim/arim.ini_
  * mycall =
  * gridsq = CN88

* Run arim again and attach to the tnc 1
  * press space bar
  * type: att 1

* Use the ping command to verify a connection
  * press space bar
  * type: ```ping <callsign> <number of pings to send>```
    * ie: ``` ping n7nix 2```


### .asoundrc file reference

* [Why asoundrc](https://www.alsa-project.org/wiki/Asoundrc)

* __NOTE:__ run aplay -l to determine sound card number.
* __NOTE: pcm "hw:1,0" line__
  * This line must match the sound card number from running aplay -l
  * ie. _hw:1,0_, refers to card #1


## For a udrc/DRAWS hat running pulse audio in split channel mode


```
pcm.ARDOP {
        type rate
        slave {
        pcm "hw:1,0"
        rate 12000
        }
}
```

## For an IC-7300 which has an internal sound card

* This config does NOT use a udrc/DRAWS hat
* IC-7300 sound card PCM connects to RPi via USB cable

* When you plug in the USB cable to the RPI from the IC-7300 it
becomes card 1, the udrc becomes card 2 and the RPi internal sound
card remains as card 0.
  * _CODEC_ is the name of the IC-7300 sound card device

```
Playback Devices

# Internal RPi audio device
Card 0, ID `ALSA', name `bcm2835 ALSA'
  Device hw:0,0 ID `bcm2835 ALSA', name `bcm2835 ALSA', 7 subdevices (7 available)

# IC-7300 audio device
Card 1, ID `CODEC', name `USB Audio CODEC'
  Device hw:1,0 ID `USB Audio', name `USB Audio', 1 subdevices (0 available)

# UDRC/DRAWS hat audio device
Card 2, ID `udrc', name `udrc'
  Device hw:2,0 ID `bcm2835-i2s-tlv320aic32x4-hifi tlv320aic32x4-hifi-0', name `', 1 subdevices (1 available)
```

* The following .asoundrc config file references the IC-7300 audio device
  * Note the __rate__ parameter has changed
```
pcm.ARDOP {
        type rate
        slave {
        pcm "hw:1,0"
        rate 48000
        }
}
```
##### Command line to start piardopc

* .asoundrc configuration file must be edited, see above

```
./piardopc 8515 pcm.ARDOP pcm.ARDOP -p /dev/ttyUSB0
```

## Stop Direwolf

* Make sure ax25/direwolf is not running
```
ax25-stop
```
* Verify ax.25/direwolf status
```
ax25-status
```
* Open a console and type the following:
  * For left mDin6 connector on a DRAWS hat _GPIO=12_
  * For left mDin6 connector on a UDRC II hat _GPIO=23_

```
cd
cd bin
```
