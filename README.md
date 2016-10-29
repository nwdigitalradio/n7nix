# Miscellaneous collection of Install scripts & Utilities

### Introduction

This repo contains scripts & notes for taking a new COMPASS image and
creating a working image that runs the following:
* direwolf
* ax.25
* paclink-unix
* a remote host wifi access point ie. not connected to a network
* a minimal mail server for paclink-unix to use any e-mail client.

### ax25
* Insert a valid ax.25 port name into /etc/ax25/axports file

### deviation

* script that generates a tone file using sox, turns on correct PTT
gpio and plays wave file through a UDRC

### direwolf

* script that tries to locate the current direwolf config file, copy
it to /etc and modify it to work with a UDRC

### hostap

* script to configure dnsmasq, hostapd & iptables to create a WiFi
access point that isn't connected to a network.

* This configuration is to allow WiFi devices to access a RPi &
compose e-mail messages using an IMAP client for the paclink-unix
Winlink message client.

### mailserv

* script to configure a minimal IMAP e-mail server used to compose
Winlink messages via paclink-unix

### systemd

* Script to configure the following to start at boot up using systemd
transaction files.
  * ax.25
  * direwolf
  * mheardd