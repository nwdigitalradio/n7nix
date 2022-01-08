## How to run both 1200 & 9600 baud on a DRAWS Hat

### Introduction

Went through the following iterations:

##### 1. Using PulseAudio #####

  * Some time ago PulseAudio switched from running in system space to user space
    * That change caused increased latency and initial tests showed that packet connected modes were severely affected

##### 2. Manually change Direwolf baud rate #####

* Manually change Direwolf baud rate with a script (_speed_switch.sh_)
  * The _speed_switch.sh_ script provides a reliable way to switch between two baud rates

##### 3. Remotely change baud rate using Direwolf Touch Tone #####
* [Remotely change baud rate using Direwolf Touch Tone capability](https://github.com/nwdigitalradio/n7nix/tree/master/baudrate/README_TOUCHTONE.md)
  * This provides a way to remotely run the _speed_switch.sh_ script

##### 4. Use __both__ ports of a DRAWS hat with custom cable #####
* Use __both__ ports of a DRAWS hat to have 1200 & 9600 baud active on a single RF channel.
  * This is the simplest and most reliable way to run both 1200 & 9600 baud packet on the same RF channel at the same time.
  * It requires a Y mini Din6 cable to connect both the DRAWS mini Din6 connectors together.

The remainder of this README is for the last method using __both__ ports of a DRAWS hat.

### Radio configuration

* The _both_baud.sh_ script modifies the _/etc/ax25/port.conf_ file
  * The _port.conf_ config file is used by the *setalsa_<radio_name>.sh* script to set up both channels of the DRAWS codec.
* Set radio to 9600 DATSPD, to enable using discriminator output from the radio.

### Software Installation

* This installation has only been tested with the following apps:
  * Winlink email client
  * Linux RMS Gateway
  * APRS using APRX & nixtracker

* run script _both_baud.sh_
  * Since the _both_baud.sh_ script modifies _/etc/ax25/port.conf_ file you must run your *setalsa_<radio_name>.sh* script
  * ie. run *setalsa_tmv71a.sh* for the Kenwood TM-V71a radio

### Making a Custom Mini Din 6 Y Cable ###


![mDin6 Y Cable before heat shrink](https://github.com/nwdigitalradio/n7nix-binary/blob/main/mdin6_Ycable_1.jpg)

![mDin6 Y Cable after heat shring](https://github.com/nwdigitalradio/n7nix-binary/blob/main/mdin6_Ycable_2.jpg)

* Assuming you are using a kennwood TM-V71a radio, run the following scripts:
```
~/n7nix/baudrate/both_baud.sh
setalsa_tmv71a.sh
ax25-restart
```

## Using Apps with 'Both Baud' Configuration

### Winlink email using paclink-unix

* Note that after running _both_baud.sh_ script DRAWS:
  * left port udr0 is configured to run at 9600 baud
  * right port udr1 is configured to run at 1200 baud

###### Command to send packets at 9600 baud P2P to station KF7FIT
```
wl2kax25 -c kf7fit -a udr0
```
###### Command to send packets at 1200 baud P2P to station KF7FIT
```
wl2kax25 -c kf7fit -a udr1
```

### Winlink gateway & Winlink P2P using Linux RMS Gateway & paclink-unix
###### Configuration file /usr/local/etc/ax25/ax25d.conf
* DRAWS port udr0 used for 9600 baud
* DRAWS port udr1 used for 1200 baud

```
[N7NIX-10 VIA udr0]
NOCALL   * * * * * *  L
default  * * * * * *  - rmsgw /usr/local/bin/rmsgw rmsgw -P %d %U
#
[N7NIX VIA udr0]
NOCALL   * * * * * *  L
default  * * * * * *  - pi /usr/local/bin/wl2kax25d wl2kax25d -c %U -a %d
#
[N7NIX-10 VIA udr1]
NOCALL   * * * * * *  L
default  * * * * * *  - rmsgw /usr/local/bin/rmsgw rmsgw -P %d %U
#
[N7NIX VIA udr1]
NOCALL   * * * * * *  L
default  * * * * * *  - pi /usr/local/bin/wl2kax25d wl2kax25d -c %U -a %d
```

### APRS gateway using APRX

##### Configuration for N7NIX-4 using 9600 baud and N7NIX-5 using 1200 baud packet
###### Configuration file /etc/aprx.conf
```
mycall N7NIX-4

<interface>
  callsign $mycall
  ax25-device $mycall
  tx-ok true
</interface>

<interface>
  callsign N7NIX-5
  ax25-device N7NIX-5
  tx-ok true
</interface>
```
