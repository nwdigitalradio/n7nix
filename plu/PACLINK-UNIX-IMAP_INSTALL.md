# Linux paclink-unix install for UDRC

## Install core components

* This installation assumes you have already [installed core components](CORE_INSTALL.md)


## Install paclink-unix Dovecot & hostap

* This script will install the following:
  * paclink-unix basic
  * dovecot imap mail server
  * hostap for WiFi connection
  * iptables for NAT
  * dnsmasq for DHCP & DNS to enable mobile device connection without
  Internet
  * node.js for web app control of paclink-unix

```bash
sudo su
cd config
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
