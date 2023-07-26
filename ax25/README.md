# AX.25 Script Utilities

### Script Index
* [ax25-setcfg.sh](#ax25-setcfgsh)
* [ax25-restart](#ax25-restart)
* [ax25-showcfg.sh](#ax25-showcfgsh)

### Install / Refresh

* To get latest version of scripts
```
cd
cd n7nix
git pull
cd config
./bin_refresh.sh
```

### PERSIST, SLOTTIME, TXDELAY, TXTAIL Definitions

##### PERSIST & SLOTTIME
* persistence parameter, scaled to the range 0 - 255 as a percent. 100%=255.
* slottime - How long to wait after detecting a _busy line_ before checking the percentage chance on the persistence setting.

The algorithm used with the PERSIST and SLOTTIME parameters helps avoid
collisions by randomizing the wait time before transmitting. The more random the timing
the less chance of two TNCs transmitting at the same time and colliding.

* An example for calculating PERSIST value based upon number of users of the channel
  * PERSIST = (256/users)-1; (from: A handbook for K9NG protocol 9600 baud packet Version 2.0, June 13, 1994)
  * if channel is clean, 63 is a reasonable PERSIST value;
  * if channel is busy, guesstimate the average number of users active at one time,
    * divide 256 by this number, then subtract 1, i.e. 4 users = (256/4) = 64 -1 = 63

##### TXDELAY
* TXDELAY - Sets the time delay between Push-to-Talk and the beginning of data.
* How long after bringing the transmitter up to wait before sending data.
* should be adjusted to allow radio sufficient time to switch from receive mode to transmit mode and develop full power output.
  * depends on your radio and recovery time of the slowest station on channel that you wish to work;
    * set for best throughput with all radios involved on channel
* 1200 baud: 100-700
* 9600 baud: 50-150

##### TXTAIL
* How long to hold the transmitter on after data has been sent
* 1200 baud: 100
* 9600 baud: 50

## Script Descriptions

#### ax25-setcfg.sh

* This script only manipulates kiss parameters: PERSIST, SLOTTIME TXDELAY & TXTAIL
  * To change AX.25 parameters T1_TIMEOUT & T2_TIMEOUT edit _/etc/ax25/port.conf_ file
  * kiss parameters are save to file: _/etc/ax25/port.conf_

* Uses program _kissparms_ to dynamically configure KISS settings that have been setup for AX.25 use by kissattach.
  * See _man kissparms_ to learn more about that program
  * _kissparms_ is part of the ax25tools package
* KISS parameters may be set at any time during the operation of the AX.25 port
  * Do NOT need to reboot or reset AX.25 for KISS parameter changes to take effect.

```
ax25-setcfg.sh -h

Usage:  [-d][-k][-h][[--port <val>][--baudrate <val>][--persist <val>][--slottime <val>][--txdelay <val>][--txtail <val>][-s]
 default Direwolf parameters:
 --slottime 10, --persist 63, --txdelay 30, --txtail 10
   -d          set debug flag
   -k          Display kissparms only
   -s          Save parameters to a file
   -h          Display this message
   --port <val>      Select port number (0 - left, 1 - right) default 0
   --baudrate <val>  Set baudrate (1200 or 9600) default 1200
   --persist <val>   Set persist (0-255)
   --slottime <val>  Set slottime in mSec (0-500, steps of 10 mSec)
   --txdelay <val>   Set txdelay in mSec(0-500, steps of 10 mSec)
   --txtail <val>    Set txtail in mSec (0-500, steps of 10 mSec)
```
* Argument position dependencies
  * If debug information is required dash d (-d) needs to be the first argument
  * To save parameters specified on the command line dash s (-s) needs to be the last argument

##### Example How To Use

* To display current AX.25 parameter settings

```
ax25-setcfg.sh -k

port: 0, speed: 1200, slottime: 200, txdelay: 500, txtail: 100, persist: 32, t1 timeout: 3000, t2 timeout: 1000
port: 0, speed: 9600, slottime:  10, txdelay: 150, txtail:  50, persist: 32, t1 timeout: 2000, t2 timeout:  100
```

* To test some AX.25 parameters (txdelay, txtail) without saving to file
```
ax25-setcfg.sh --txdelay 200 --txtail 50

setting TXDELAY to: 200
setting TXTAIL to: 50
KISSPARMS set to:
port: 0, speed: 1200, slottime: 200, txdelay: 200, txtail: 50, persist: 32, t1 timeout: 3000, t2 timeout: 1000
```
* To change all AX.25 parameters without saving to file
```
ax25-setcfg.sh  --slottime 200 --persist 32 --txdelay 500 --txtail 100

etting SLOTTIME to: 200, for baudrate: 1200
setting PERSIST to: 32
setting TXDELAY to: 500
setting TXTAIL to: 100
KISSPARMS set to:
port: 0, speed: 1200, slottime: 200, txdelay: 500, txtail: 100, persist: 32, t1 timeout: 3000, t2 timeout: 1000
```

* To save parameters set on the command line so that they persist between reboot
  * __Important__ that dash s option is at end of argument list
```
ax25-setcfg.sh --txdelay 200 --txtail 50 -s

setting TXDELAY to: 200
setting TXTAIL to: 50
Saving AX.25 parameters to file /etc/ax25/port.conf
KISSPARMS set to:
port: 0, speed: 1200, slottime: 200, txdelay: 200, txtail: 50, persist: 32, t1 timeout: 3000, t2 timeout: 1000
```

#### ax25-restart

* Stops & starts AX.25/direwolf so that any new configuration changes take effect.

#### ax25-showcfg.sh
```
ax25-showcfg.sh -h

Usage: ax25-showcfg.sh [-d][-k][-h]
   -d        set debug flag
   -k        Display kissparms only
   -h        no arg, display this message
```

#### List current versions of AX.25 lib/apps/tools
```
dpkg -l *ax25*

||/ Name           Version      Architecture Description
+++-==============-============-============-=================================================
ii  ax25apps       2.0.1-1      armhf        AX.25 ham radio applications
ii  ax25tools      1.0.5-1      armhf        Tools used to configure an ax.25 enabled computer
ii  libax25        1.1.3-1      armhf        AX.25 library for hamradio applications
```

#### aprs_cs_collect.sh aprs_cs_report.sh

```
listen -a | ./aprs_cs_collect.sh
```
```
aprs_cs_report.sh -h
APRS call sign report Ver: 1.2 started: Fri 21 Jul 2023 11:59:58 AM PDT
Usage: aprs_cs_report.sh [-p <1|2|etc>][-h]
   no args           display today's call sign report file
   -p <1|2|3|etc>    days previous report file
   -h                display this message.
```
