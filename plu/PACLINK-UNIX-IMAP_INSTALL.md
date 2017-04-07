# Linux paclink-unix install for UDRC

## Install core components

* This installation assumes you have already [installed core components](https://github.com/nwdigitalradio/n7nix/blob/master/CORE_INSTALL.md)


## Install paclink-unix, Dovecot & hostap

* This script will install the following:
  * paclink-unix basic
  * dovecot imap mail server
  * hostap for WiFi connection
  * iptables for NAT
  * dnsmasq for DHCP & DNS to enable mobile device connection without
  Internet
  * node.js for web app control of paclink-unix

* You will be required to enter:
  * callsign
  * Winlink password
  * Real name
* To create an SSL certificate you will be required to enter:
  * Country name (2 letter code)
  * State or province (full name)
  * Locality (eg. city)
  * Organization name, skip
  * Organizational Unit Name, skip
  * server FQDN ( eg. check_test5.localnet
  * email address
* For host access point
  * SSID (eg. bacon)

```bash
sudo su
cd n7nix/config
./app_install.sh pluimap
```
* Upon completion you should see:

```
paclink-unix with imap, install script FINISHED
```

## Start paclink-unix webserver

* In a separate console window start up the node.js server for
paclink-unix control.

```bash
sudo su
cd /usr/local/src/paclink-unix/webapp
nodejs plu-server.js
````
