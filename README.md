# Install scripts for some packet functionality

### Introduction

This repo contains scripts & notes for taking a new COMPASS image and
creating a working image that will boot up & run the following:
* direwolf
* ax.25
* RMS Gateway
* [paclink-unix](http://bazaudi.com/plu/doku.php)
  * There are no install scripts for paclink-unix
  * A Debian install package is being worked on, until then use the link above.
* a remote host wifi access point ie. not connected to a network
* a minimal mail server for paclink-unix to use any e-mail client.

See
[RMSGW_INSTALL.md](https://github.com/nwdigitalradio/n7nix/blob/master/RMSGW_INSTALL.md)
for details on installing RMS Gateway functionality.  Briefly the first script to run is
[config/init_install.sh](https://github.com/nwdigitalradio/n7nix/blob/master/COMPASS_CFG.md)
which will do the initial configuring of the compass kernel & install
AX.25 & direwolf.  After that the configure scripts are run for each
subsection.  See
[config/app_install.sh](https://github.com/nwdigitalradio/n7nix/tree/master/config/app_install.sh)
for installing all apps required for RMS Gateway.

Note _deviation_ is not part of the install process.


### [ax25](https://github.com/nwdigitalradio/n7nix/tree/master/ax25)
* Insert a valid ax.25 port name into /etc/ax25/axports file

### [direwolf](https://github.com/nwdigitalradio/n7nix/tree/master/direwolf)

* script that tries to locate the current direwolf config file, copy
it to /etc and modify it to work with a UDRC

### [hostap](https://github.com/nwdigitalradio/n7nix/tree/master/hostap)

* script to configure dnsmasq, hostapd & iptables to create a WiFi
access point that isn't connected to a network.

* This configuration is to allow WiFi devices to access a RPi &
compose e-mail messages using an IMAP client for the paclink-unix
Winlink message client.

### [mailserv](https://github.com/nwdigitalradio/n7nix/tree/master/mailserv)

* script to configure a minimal IMAP e-mail server used to compose
Winlink messages via paclink-unix

### [systemd](https://github.com/nwdigitalradio/n7nix/tree/master/systemd)

* Script to configure the following to start at boot up using systemd
transaction files.
  * ax.25
  * direwolf
  * mheardd

### [deviation](https://github.com/nwdigitalradio/n7nix/tree/master/deviation)

* Script that generates a tone file using sox, turns on correct PTT
gpio and plays wave file through a UDRC
* Generating a tone sine wave is one part of measuring deviation. The
other part is doing the actual measurement. The [Xastir
wiki](http://xastir.org/index.php/HowTo:Set_Deviation_via_RTL) has a
nice article on how to do that using an RTL SDR dongle.
