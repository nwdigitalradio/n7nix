## To Install ardopc & arim

```
cd
cd n7nix/ardop
./ardop_install.sh
```

#### Run ardopc
* Make sure ax25/direwolf is not running
```
ax25-stop
```
* Verify ax.25/direwolf status
```
ax25-status
```
* Open a console and type the following:
  * For left mDin6 connector on the DRAWS hat _GPIO=12_

```
cd
cd bin
```
* __Assuming only RPi internal sound device is installed__
* __For a DRAWS hat__ left mDin6 connector
```
./piardopc 8515 plughw:1,0 plughw:1,0 -p GPIO=12
```
* __For a UDRC II hat__ left mDin6 connector
```
./piardopc 8515 plughw:1,0 plughw:1,0 -p GPIO=23
```

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