## Configuring UDRC/DRAWS Two Audio Channels

Goal was to configure both the UDRC/DRAWS HAT sound ports from a single file.

##### Configuration parameters available.

The two main features that can be configured for each sound card channel:

* enable use by Direwolf for packet
* enable use by an HF digital mode.
  * Using one channel for each Direwolf packet & HF digital is called __split channel__.

The prototype port.conf file in directory /etc/ax25 is listed below.

```
[port0]
speed=1200
ip_address="192.168.255.2"
receive_out=audio

[port1]
speed=1200
ip_address="192.168.255.3"
receive_out=audio

[baud_1200]
slottime=200
txdelay=500
t1_timeout=3000
t2_timeout=1000

[[baud_9600]
slottime=10
txdelay=150
t1_timeout=2000
t2_timeout=100
```

#### Changing config file
* Any changes made to this config file that leaves at least one channel used by Direwolf (packet)
  * Run _ax25-restart_

* If sound card channels are to be used for HF programs and not for Direwolf (packet)
  * Run _ax25-stop_

#### To enable split channel mode

* Install split channel files
  * Will install pulseaudio, and a number of configuration files
  * Will modify _/etc/direwolf.conf_, _/etc/ax25/port.conf_
```
cd
cd n7nix/splitchan
./split_install.sh
```

* Direwolf packet mode uses left channel
  * Active port is _udr0_
  * Set _speed=_ for port0 to either 1200 or 9600
* Run HF digital mode on right channel
  * Set _speed=_ for port1 to off (_speed=off_)

* Using the left channel (mDin6 connector) for Direwolf keeps the device
name udr0 on that channel


#### To use both sound card channels for HF digital modes

* Run _ax25-stop_

#### To run Direwolf packet mode on both channels

* Active ports are _udr0_ (left) or _udr1_ (right)
* Set _speed=_ for both port0 & port1 to either 1200 or 9600
* Run _ax25-start_

### To change baud rate speeds on either channel

* Edit speed=
* Run _ax25-restart_

### To route received audio discriminator or precomp/decomp
* For either audio channel edit receive_out
* To use precomp/decomp
  * _receive_out=audio_
* To use discriminator
  * _receive_out=disc_


## Programs that use port.conf

* setalsa-
  * udrc-echolink.sh
  * tmv71a.sh
* ax25-start
* ax25-stop
* ax25-upd
* ax25dev-parms
* ax25/config.sh
* ax25-showchfg.sh
* speed_switch.sh
* split_chan.sh
* split_install.sh
