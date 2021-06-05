## Script notes for this directory

### set_callsign.sh
* This script edits the config files for the following programs:
  * Direwolf
  * AX.25
  * ax25d
  * RMS Gateway
  * Winlink (paclink-unix)
  * Mutt

```
./set_callsign.sh -h
Usage:  [-p][-d][-h]
                  No args will display call signs configured
  -p              Print call signs used
  -s <callsign>   Set new callsign
  -B              Backup config files
  -D              Diff config files
  -R              Resotre config files
  -d              Set DEBUG flag
  -h              Display this message.
```

##### How to use:

* On a Raspberry PI with the NWDR image go to the configuration directory:
  * This will be the location of the _set_callsign.sh_ script

```
cd
cd n7nix/config
```

###### Display current call signs in config
```
./set_callsign.sh
# or
./set_callsign.sh -p
```

###### Back-up current call sign configuration
```
./set_callsign.sh -B
```
###### Set call sign
* Example using call sign N0one
```
./set_callsign.sh -s N0ONE
```
* You will be prompted for a "real" name
  * Use first & last name and hit return

###### Compare changes with saved configuration
```
./set_callsign.sh  -D
```
* If the configuration looks OK then restart AX25 & Direwolf and test.
```
ax25-restart
```

###### Restore saved configuration
* If after running the set_callsign script the configuration has a problem then restore previous configuration
```
./set_callsign.sh -R
```
