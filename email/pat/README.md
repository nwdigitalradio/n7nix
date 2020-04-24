## How to run PAT with ARDOP - PRELIMINARY

### List of processes running to support PAT/ARDOP
```
pi        5598  0.1  0.6 928304 13864 pts/7    Sl+  Apr21   3:59 pat http
pi       12767  8.5  0.1   5736  3580 pts/10   S+   Apr22 112:25 ./piardopc 8515 plughw:1,0 plughw:1,0 -p GPIO=12
pi       13585  0.0  0.4 911528  9676 pts/9    Sl+  Apr22   0:09 pat --listen=ardop interactive
pi       18821  0.5  2.8 258144 55992 pts/8    Sl+  Apr21  15:06 ./piARDOP_GUI
pi        6257  0.0  0.3  28100  7748 pts/0    Sl+  Apr21   0:00 rigctld -m311 -r /dev/ttyUSB0 -s 4800
```

#### PAT config
* PAT config file lives here: _.wl2k/config.json_
  * __NOTE__ preceeding dot in directory name
* Edit the following configuration variables
  * mycall
  * secure_login_password
  * locator


### Consoles

#### Console 1: ARDOP

* From your local bin directory start ARDOP
  * The following is for a DRAWS hat

```
cd ~/bin
./piardopc 8515 plughw:1,0 plughw:1,0 -p GPIO=12
```

#### Console 2: ARDOP listener

```
pat --listen="ardop" interactive
```

#### Console 3: Rig control

* [PAT Rig Control](https://github.com/la5nta/pat/wiki/Rig-control) wiki.
* Edit PAT config file config.json
  * Add an entry to _hamlib_rigs_
  * ie. For an IC-706MKIIG
```
 "IC-706MKIIG": {"address": "localhost:4532", "network": "tcp"}
```
  * Under "ardop": add a rig control (rigctl) rig name.
    * Must match a name from ```rigctl -l``` list
```
  "rig": "IC-706MKIIG",
```

* Start rig control daemon in another console
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

#### Console 4: Waterfall

* For a visual waterfall run piARDOP_GUI
  * From a console running on the RPi desktop
```
cd ~/bin
./piARDOP_GUI
```

### Winlink Point to point connection
* [Verify Pat listener is running](#console-2-ardop-listener)

```
pat connect ardop:///AF4PM?freq=7101
```

### RMS Gateway Winlink connection
* To get a list of RMS Gateways

##### Using PAT applicaton
* List stations with call sign prefix
  * _dist_ is distance from your grid square in kilometers.

* Will list stations with call sign prefix N7

```
$ pat rmslist -s -m ardop N7
callsign  [gridsq] dist    Az mode(s)              dial freq    center freq url
N7LOB     [CN86BX] 183    139 ARDOP 2000        3.589.50 MHz   3.591.00 MHz ardop:///N7LOB?freq=3589.5
```
* Will list stations with call sign prefix K7

```
$ pat rmslist -s -m ardop K7
callsign  [gridsq] dist    Az mode(s)              dial freq    center freq url
K7NHV     [CN87SK] 120    165 ARDOP 2000        3.597.30 MHz   3.598.80 MHz ardop:///K7NHV?freq=3597.3
K7NHV     [CN87SK] 120    165 ARDOP 2000       10.145.00 MHz  10.146.50 MHz ardop:///K7NHV?freq=10145
K7NHV     [CN87SK] 120    165 ARDOP 2000        7.102.20 MHz   7.103.70 MHz ardop:///K7NHV?freq=7102.2

K7HTZ     [CN87OD] 148    178 ARDOP 2000        3.587.50 MHz   3.589.00 MHz ardop:///K7HTZ?freq=3587.5
K7HTZ     [CN87OD] 148    178 ARDOP 2000        7.101.20 MHz   7.102.70 MHz ardop:///K7HTZ?freq=7101.2
K7HTZ     [CN87OD] 148    178 ARDOP 2000       10.144.70 MHz  10.146.20 MHz ardop:///K7HTZ?freq=10144.7
K7HTZ     [CN87OD] 148    178 ARDOP 2000       14.108.50 MHz  14.110.00 MHz ardop:///K7HTZ?freq=14108.5

K7IF      [CN87OA] 162    178 ARDOP 2000        3.588.40 MHz   3.589.90 MHz ardop:///K7IF?freq=3588.4
K7IF      [CN87OA] 162    178 ARDOP 2000        7.101.90 MHz   7.103.40 MHz ardop:///K7IF?freq=7101.9
K7IF      [CN87OA] 162    178 ARDOP 2000       10.144.90 MHz  10.146.40 MHz ardop:///K7IF?freq=10144.9
K7IF      [CN87OA] 162    178 ARDOP 2000       14.095.50 MHz  14.097.00 MHz ardop:///K7IF?freq=14095.5
```


##### Using N7NIX script
* Using [Winlink Web Services](https://cms.winlink.org/json/metadata?op=GatewayProximity) get gateway proximity list for ARDOP
  * Defaults to grid square of CN88nl & a distance of 140 miles
  * __NOTE:__ This script lists __Center Frequency__ to get __Dial Frequency__ subtract 1500 KHz.

```
cd
cd n7nix/ardop

# List command line arguments

./ardoplist.sh -h

Usage:  [-s <winlink_service_name][-d][-f][-h][-D <distance][-g <grid_square>]
                       Default to display Winlink PROXIMITY service.
  -D <distance>        Set distance in miles
  -g <grid_square>     Set location grid square ie. CN88nl
  -s <winlink_service> Specify Winlink service,: status, proximity or listing
  -f                   Force update of service file
  -d                   Set DEBUG flag
  -h                   Display this message.
```

* Run using defaults

```
./ardoplist.sh -h
Using distance of 140 miles & grid square cn88nl

Generated new /home/pi/tmp/ardop/ardopprox.json file

 Callsign        Frequency  Distance    Baud
 K7NHV     	   3598800	75	 600
 K7NHV     	   7103700	75	 600
 K7NHV     	  10146500	75	 600
 K7HTZ     	   3589000	92	 600
 K7HTZ     	   7102700	92	 600
 K7HTZ     	  10146200	92	 600
 K7HTZ     	  14110000	92	 600
 K7IF      	   3589900	101	 600
 K7IF      	   7103400	101	 600
 K7IF      	  10146400	101	 600
 K7IF      	  14097000	101	 600
 N7LOB     	   3591000	114	 600
Total gateways: 12, total call signs: 4
```
### Winlink RMS Gateway connection


* To connect to an RMS Gateway on 80 M
```
pat connect ardop:///K7IF?freq=3588.4
```

