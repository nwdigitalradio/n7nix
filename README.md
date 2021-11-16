# Install scripts for some packet functionality

## Introduction

This repository contains scripts & notes for taking a Linux Raspbian
distribution and creating a working image that will run packet, HF
programs or both. The [NWDR image](http://nwdig.net/downloads/) has
already installed a number of popular programs so that **ONLY**
configuration is required.

  * Since the sound CODEC is a stereo device there are 2 audio
  channels that may be split between packet & HF program usage.

#### HF Program configuration

* The NWDR image defaults to this configuration.
* In this configuration an HF program (fldigi, wsjt-x, ARDOP, etc) controls the sound CODEC
* [List of HF programs currently on the NWDR image](docs/IMAGE_README.md)

#### Packet Configurations:
* Core only: This includes
[direwolf](https://github.com/wb2osz/direwolf/blob/master/README.md)
& [AX.25](https://github.com/ve7fet/linuxax25) with no other
application running.
* Linux RMS Gateway for Winlink
* Winlink client: paclink-unix in two flavors

  * paclink-unix min which installs postfix and a console base email
    client.
  * paclink-unix default which allows using any e-mail client that
  supports
  [IMAP](https://en.wikipedia.org/wiki/Internet_Message_Access_Protocol).
* APRS client: Xastir, YAAC, nixtracker
* APRS digipeater & iGate: aprx

#### Both HF programs & Packet at the same time
* Split channel scripts control configuring the audio CODEC channels.


## Configuration scripts

The NWDR image has installed all software listed [here](docs/IMAGE_README.md)

**Note:** These configuration scripts were meant to be run **once only**
starting from a clean image. They might work if used more than once
but they were not tested for that case. If an installation fails I
would like to know about it. Please post any problems you might have
on the [UDRC forum](https://nw-digital-radio.groups.io/g/udrc/).




Whether using HF programs or packet you **MUST** set _deviation_ using
[ALSA](https://en.wikipedia.org/wiki/Advanced_Linux_Sound_Architecture)
settings for your specific radio.  [draws-manager](../manager)
and [measure_deviate.sh script](deviation) help determine these
settings. Usually for a particular radio the 1200 baud & 9600 baud
ALSA settings will be different.

As of around August 2019 main line Linux kernel has a driver
for the Texas Instruments tlv320aic32x4 DSP sound chip that can be
used by UDRC/DRAWS HAT.

The NW Digital Radio [UDRC
II](https://github.com/nwdigitalradio/n7nix-binary/blob/main/UDRC-IIDS.pdf)
or
[DRAWS](https://nw-digital-radio.groups.io/g/udrc/files/DRAWSBrochure-1.pdf)
are [HATS](https://github.com/raspberrypi/hats) that contains the
tlv320aic32x4 DSP sound chip plus routes GPIO pins to control PTT.
They also have a 12V to 5V buck regulator so that you can run the Pi
with the HAT from a 12V supply. DRAWS also has a [SkyTraq S1216F8-GL
GNSS GPS Module](http://www.skytraq.com.tw/datasheet/S1216V8_v0.9.pdf)
and an [TI TLA2024 4 channel A/D
converter](https://www.ti.com/lit/ds/symlink/tla2024.pdf?&ts=1589647159814)
accessed by the 8 pin Auxiliary connector.

* For packet, only the direwolf configuration is specific to the [UDRC
II](http://nwdigitalradio.com/wp-content/uploads/2012/04/UDRC-IIDS.pdf)
or
[DRAWS](https://nw-digital-radio.groups.io/g/udrc/files/DRAWSBrochure-1.pdf)
hardware.

* For HF programs, you must use the proper sound card device name for both Capture and Playback devices.
  * Each HF program may have a different syntax for referencing the
  device, for example:
```
udrc: - (hw:0,0)
```
or
```
input:plughw:CARD=udrc,DEV=0
output: plughw:CARD=udrc,DEV=0
```

### Core

Regardless of what functionality you want to install the first thing to run is
[core_install.sh](https://github.com/nwdigitalradio/n7nix/blob/master/docs/CORE_INSTALL.md)
which will do the initial configuring of the [Raspbian kernel](https://www.raspberrypi.org/downloads/raspbian/) & install
AX.25 & direwolf.

**Core is required for all packet apps using a UDRC or DRAWS HAT**. This option
installs
[direwolf](https://github.com/nwdigitalradio/n7nix/tree/master/direwolf)
& [AX.25](https://github.com/nwdigitalradio/n7nix/tree/master/ax25)
tools/apps/library.  Use this option if you want to run APRS or
some packet client that uses direwolf or AX.25. As part of the core
requirements this option also configures
[systemd](https://github.com/nwdigitalradio/n7nix/tree/master/systemd)
to start direwolf, AX.25 attach & AX.25 apps like mheardd at boot time.

### Packet App Configuration
#### RMS Gateway

In order to install the Linux RMS Gateway you must register with Winlink to get a
password for a gateway.

See
[RMSGW_INSTALL.md](https://github.com/nwdigitalradio/n7nix/blob/master/rmsgw/README.md)
for details on installing RMS Gateway functionality.

* See app install script: [config/app_install.sh](config/app_install.sh)
for installing all apps required for RMS Gateway.

#### paclink-unix

* [Installation options](plu/README.md)
* paclink-unix will work with any Linux email client that supports
[IMAP](https://en.wikipedia.org/wiki/Internet_Message_Access_Protocol)
for retrieving email messages

##### 3 email clients supported with install scripts


* Command line client: mutt
* Native Linux client: [Claws-mail](https://github.com/nwdigitalradio/n7nix/blob/master/email/claws/README.md)
* Web based
[rainloop](https://github.com/nwdigitalradio/n7nix/blob/master/email/rainloop/README.md)

#### aprs

* [aprx](aprx)
* [nixtracker](tracker)
* [xastir](xastir)
* [yaac](yaac)

### Other

#### [deviation](https://github.com/nwdigitalradio/n7nix/tree/master/deviation)

* Script that generates a tone file using sox, turns on correct PTT
gpio and plays wave file through a UDRC II or DRAWS HAT.
* Generating a tone sine wave is one part of measuring deviation. The
other part is doing the actual measurement. The [Xastir
wiki](http://xastir.org/index.php/HowTo:Set_Deviation_via_RTL) has a
nice article on how to do that using an RTL SDR dongle.

#### [vnc](https://github.com/nwdigitalradio/n7nix/blob/master/vnc)

* systemd service file supplied by Ken Koster N7IPB.

#### uronode
