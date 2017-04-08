# Linux paclink-unix install for UDRC

## Install core components

* This installation assumes you have already [installed core components](https://github.com/nwdigitalradio/n7nix/blob/master/CORE_INSTALL.md)

## This script installs & configures the following:

* paclink-unix
* postfix
* mutt

## paclink-unix executables

###### wl2ktelnet
* Uses telnet protocol to connect to a Winlink Common Message Server (CMS) over the Internet.

###### wl2kax25
* Uses HAM radio to connect to a Radio Mail Server (RMS) to gateway to the Internet and connect to a CMS.

###### wl2kserial
* Nick n2qz, the founder of paclink-unix, developed wl2kserial to interface to an SCS-PTC-IIpro modem using PACTOR III.

## Install paclink-unix
* You will be required to enter the following:
  * For paclink-unix
    * callsign
    * Winlink password
  * For mutt
    * Real name (ie. Joe Blow)

### Start the install script

* Execute the following script from the directory that scripts were cloned to.

```bash
cd n7nix/config
# should now be in ~/n7nix/config
# become root
sudo su
./app_install.sh plu
```
* When the script finishes you should see:

```
mutt install/config FINISHED

app install (plu) script FINISHED
```

paclink-unix install should now be installed & functional installed.

## Verify the paclink-unix install

#### Verify message composition

* compose an e-mail with your e-mail client & verify that a new file appears in /usr/local/var/outbox

#### Verify Winlink telnet connection - wl2ktelnet test

* Default parameters for wl2ktelnet should be sufficient
  * As your login user (pi) execute:

```bash
wl2ktelnet
```

#### Verify a radio connection - wl2kax25 test

* Find an RMS Gateways near you
  * Go to http://winlink.org/RMSChannels
    * Click on the _Packet_ button & locate your area on the map
  * run either of these script found in https://github.com/nwdigitalradio/Winlink4Linux
    * gatewaylist.sh
    * rmslist.sh

```bash
wl2kax25 -c <some_RMS_Gateway>
# or
wl2kax25 -c <some_RMS_Gateway> <some_digipeater>
```
