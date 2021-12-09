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
[Follow this link to setup audio alerts for Xastir](https://github.com/nwdigitalradio/n7nix/blob/master/xastir/README_AUDIO.md)

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