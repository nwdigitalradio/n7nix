#HSLIDE

## Winlink & the Raspberry Pi
###### Basil Gunn  N7NIX,  last edit March 29, 2017
###### https://gitpitch.com/nwdigitalradio/n7nix

#HSLIDE

## What is Winlink
* Radio messaging system administered by volunteers that uses HAM radio frequencies.
* Takes SMTP compliant e-mail messages and using B2 Forwarding Protocol transports them via:
  * Amateur radio
  * Telnet

#HSLIDE

## Winlink components

* CMS - Common Message Server
  * maintained by Winlink
* RMS - Radio Mail Server
  * maintained by you
* Client e-mail message mangler

#HSLIDE

## Why the Pi?

* Raspberry Pi 3 power draw:
  * 1.4 W  idle
  * ~3.7 W  under heavy load
  * https://www.pidramble.com/wiki/benchmarks/power-consumption

* Runs Linux
  * Has decent uptime
  * You can control system updates

#HSLIDE

## Hardware Components

* Some TNC or sound card
  * Prefer a HAT for hardware integration, fewer cables
  * HAT = **H**ardware **A**ttached on **T**op

* Power supply or battery with trickle charger

* Internet connection

* For an RMS Gateway Winlink has expectation that you run it 24/7.

#HSLIDE

## Software Components
###### assume sound card

* Direwolf

* AX.25

* Linux RMS Gateway

* paclink-unix

##### All software is Open Source

#HSLIDE

## Direwolf

* **D**ecoded **I**nformation from **R**adio **E**missions for **W**indows **O**r **L**inux **F**ans
* Dire Wolf is a software "soundcard" modem/TNC and APRS encoder/decoder.
* Source: https://github.com/wb2osz/direwolf

#HSLIDE

## AX.25

* AX.25 (Amateur X.25) is a data link layer protocol derived from the X.25 protocol suite
* Designed for use by amateur radio packet operators
* Protocol is built into kernel
* Also has these user side components
  * ax25tools
  * ax25apps
  * libax25

#HSLIDE

## Linux RMS Packet Gateway

* A radio station running Radio Mail Server (RMS) Packet software which provides a communications path between
 a VHF or UHF packet Winlink user and the internet via a Winlink Common Message Server (CMS)

* Written & maintained by:
  * Hans-J. Barthen - DL5DI
  * Brian R. Eckert - W3SG

#VSLIDE

### Linux RMS Gateway Installation.
  * http://k4gbb.no-ip.org/docs/rmsinstdoc.html

#HSLIDE

## paclink-unix

* paclink-unix is a UNIX client for the Winlink 2000 ham radio email system.

* Written by:
  * Nick Castellano - N2QZ
  * Dana Borgman - KA1WPM
  * Basil Gunn - N7NIX

#VSLIDE

### paclink-unix

* Uses 3 programs for different transport paths
  * wl2kax25 for sending/receiving using a radio connected to an RMS
  * wl2ktelnet for sending/receiving using Internet
  * wl2kserial for send/receiving using a Pactor modem

#HSLIDE

## Resources

##### paclink-unix
* source code: https://github.com/nwdigitalradio/paclink-unix
* presentation: https://gitpitch.com/nwdigitalradio/paclink-unix/

##### Linux RMS Gateway
* source code: https://github.com/nwdigitalradio/paclink-unix
* presentation: https://gitpitch.com/nwdigitalradio/rmsgw/

#VSLIDE

##### Installation Scripts
* https://github.com/nwdigitalradio/n7nix

##### Forums
* https://groups.yahoo.com/neo/groups/paclink-unix/
* https://groups.yahoo.com/neo/groups/LinuxRMS/
* https://nw-digital-radio.groups.io/g/udrc/

##### This presentation
* https://gitpitch.com/nwdigitalradio/n7nix/
