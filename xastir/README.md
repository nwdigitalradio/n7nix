### Installation Notes for UDRC
* Preferred apt-get install xastir
* [Build from latest source](http://xastir.org/index.php/HowTo:Raspbian_Jessie)

#### Install Xastir

```
apt-get install xastir
```
* run xastir from console (where's icon on window manager ?)

#### Config Xastir
##### Configure Station
* "Configure Station" pops up
  * Enter Callsign, Lat & Long, symbol, comment

* Select maps to use: Map -> Map Chooser -> Online/OSM_tiled_mapnik.geo
  * Apply, OK, should see "Loading Weather Alert Maps"
  * Zoom map to location, are Lat/Long correct?
* If not using a DRAWS Hat then plug in USB GPS now

##### Configure interfaces
  * Configure interfaces: Interface -> Interface Control

###### Add a TNC interface
* For a UDRC II make sure _Transmit Radio Port_ is 2 if using the mDin6 connector
  * Direwolf uses port 0,1 but Xastir uses port 1,2

* Add: _Networked AGWPE_
  * Transmit RadioPort: 1
  * Igate -> RF path: Wide2-1
* Select Device 0 -> Start
  * Status should change from Down to Up

###### Add a GPS interface

* Add: _Networked GPS (via gpsd)__
* Select Device 1 -> Start
  * Status should change from Down to Up

##### Configure Audio
* Need to enable the RPi audio device
  * uncomment the following line in _/boot/config.txt_
```
# dtparam=audio=on
```
* The _Audio Play Command_ is different for analog & HDMI audio

* Download xastir sound files
```
git clone https://github.com/Xastir/xastir-sounds
cd xastir-sounds/sounds
cp *.wav /usr/share/xastir/sounds
```
* **Note:** audio device plughw:0,0 is for normal analog audio out
* File -> Configure -> Audio Alarms
  * _Audio Play Command_ for analog audio: aplay -D "plughw:0,0"
  * Select alerts: New Station, New Message, Proximity, Weather Alert

###### Only needed for HDMI audio

* **Note:** audio device plughw:0,1 is for a Sunfounder LCD display with HDMI audio

* HDMI audio starts about 2 seconds delayed
  * Make a wave file that is 2 seconds of silence
  * Just use [silence.wav file in this repo](https://github.com/nwdigitalradio/n7nix/blob/master/xastir/silence.wav)
  * Put silence.wav in Xastir sounds directory /usr/share/xastir/sounds

  * _Audio Play Command_ for HDMI:

```aplay -D "plughw:0,1" /usr/share/xastir/sounds/silence.wav```

* To make a two second silent wave file execute the following on a computer with audio input
  * Make sure the microphone is not attached.
```
rec silence.wav trim 0 02
```

* Make sure audio is routed to HDMI
```
amixer cget numid=3
```
* If value is not equal to 2 then:
```
amixer cset numid=3 2
```
* Make sure audio for bcm 2835 chip is enabled in /boot/config.txt file
```
# Enable audio (loads snd_bcm2835)
dtparam=audio=on
```

###### Verify Audio
* Play a wave file
```
cd /usr/share/xastir/sounds

# For Analog audio
aplay -D "plughw:0,0" bandopen.wav

# For HDMI audio
aplay -D "plughw:0,1" silence.wav bandopen.wav
```
* Run speaker test & listen for white noise
```
# x = 0 for analog or x = 1 for HDMI
speaker-test -D plughw:0,x -c 2
```
* List sound devices
```
aplay -l
```

###### Verify Xastir
* View -> incoming Data

#### Config Direwolf
* Using UDRC II

###### Verify /etc/direwolf.conf
```
ACHANNELS 2
MYCALL <your_callsign>-<some number>
AGWPORT 8000
KISSPORT 8001

CHANNEL 0
MODEM 1200
#MODEM 9600
PTT GPIO 12

CHANNEL 1
MODEM 1200
#MODEM 9600
PTT GPIO 23
```

#### Make a Desktop icon entry for Xastir
* Make a symbolic link to the xastir share directory desktop
```
ln -s /usr/share/applications/xastir.desktop /home/<user>/Desktop
```

* Or create this file here: `/home/<user>/Desktop/xastir.desktop`
```
[Desktop Entry]
Name=xastir
Exec=xastir
Icon=/usr/share/xastir/symbols/icon.png
Terminal=false
Type=Application
Categories=Network;Ham Radio;
Comment=X Amateur Station Tracking and Information Reporting
```

#### Debug

* Start xastir from a console
```
xastir
```