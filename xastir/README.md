### Installation Notes for UDRC
* Preferred apt-get install xastir
* [Build from latest source](http://xastir.org/index.php/HowTo:Raspbian_Jessie)

#### Config Xastir
* interface -> interface Control ->Device 1 Up Networked AGWPE localhost:8000
  * For a UDRC II make sure 'Transmit Radio Port' is 2
  * Direwolf uses port 0,1 but Xastir uses port 1,2

* After apt-get install xastir
  * run xastir from console (where's icon on window manager ?)
###### Configure Station
  * "Configure Station" pops up
    * Enter Callsign, Lat & Long, symbol, comment
  * Select maps to use: Map -> Map Chooser -> Online/OSM_tiled_mapnik.geo
    * Apply, OK, should see "Loading Weather Alert Maps"
    * Zoom map to location, are Lat/Long correct
  * Plug in USB GPS
###### Conigure interfaces
  * Configure interfaces: Interface -> Interface Control
    * Add: Networked AGWPE
      * Transmit RadioPort: 1
      * Igate -> RF path: Wide2-1
   * Select Device 0 -> Start
     * Status should change from Down to Up
   * Add: Serial GPS
     * Stand alone GPS port: /dev/ttyUSB0
   * Select Device 1 -> Start
     * Status should change from Down to Up

###### Configure Audio
* **Note:** plughw:0,1 is for a Sunfounder with HDMI audio
* File -> Configure -> Audio Alarms
  * Audio Play Command: aplay -D "plughw:0,1" Noise.wav
  * Select: New Station, New Message, Proximity, Weather Alert
* Download xastir sound files
```
https://github.com/Xastir/xastir-sounds
cd xastir-sounds/sounds
cp *.wav /usr/share/xastir/sounds
```

###### Verify Audio
* Play a wave file
```
cd /usr/share/xastir/sounds
aplay -D "plughw:0,1" bandopen.wav
```
* Run speaker test & listen for white noise
```
speaker-test -D plughw:0,1 -c 2
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
* Filename /home/<user>/Desktop/xastir.desktop
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