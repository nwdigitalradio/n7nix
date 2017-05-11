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

##### A note about the winlink password required by paclink-unix
* If you are not yet a registered Winlink user, just hit enter when prompted for the Winlink password
  * You will receive the password later on in the process from winlink.org
  * Once you receive your password you will enter it manually in file _/usr/local/etc/wl2k.conf_
    * Set the _wl2k-password=_ line with your new password.
* For new Winlink users [this link](https://winlink.org/user) has information on creating a Winlink account & getting a password.

### Start the install script

* Execute the following script from the directory that scripts were cloned to.
  * Should be starting from your login home directory eg. /home/pi

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

paclink-unix install should now be installed & functional.

## Verify the paclink-unix install

#### Verify message composition

* As your normal login user (eg. pi, not root) compose an e-mail with your e-mail client
  * Next verify that a new file appears in _/usr/local/var/wl2k/outbox_

#### Verify Winlink telnet connection - wl2ktelnet test

* Default parameters for wl2ktelnet should be sufficient
  * As your login user (pi) execute:

```bash
wl2ktelnet
```
#### Find an RMS Gateway near you - 2 methods

##### 1 - Use the winlink web site

* Go to http://winlink.org/RMSChannels
  * Click on the _Packet_ button & locate your area on the map

##### 2 - Run a script to interrogate winlink web services server
* run either of these script found in _https://github.com/nwdigitalradio/Winlink4Linux_
  * gatewaylist.sh
  * rmslist.sh
* Both of these scripts will give similar output in different formats

###### gatewaylist.sh
```bash
./gatewaylist.sh
```
* defaults set a distance of 30 miles & GRID SQUARE cn88nl
  * If you edit the script run the _-l_ option to build a new list
* requires the _cURL_ package
* Edit the _GRIDSQUARE=_ line at the top of the script with your gridsquare
* _-m `<miles>`_ sets the distance in miles of local RMS stations
* _-c_  gives a count of local stations found
* _-l_  build a new RMS station proximity list
* _-h_  lists all command line arguments

###### rmslist.sh
```bash
./rmslist.sh <integer_distance_in_miles> <maidenhead_grid_square>
```
* defaults set a distance of 30 miles & GRID SQUARE cn88nl
* requires both _cURL_ and the json parsing utility _jq_
  * If run as root will install both packages automatically
* Displays a list of RMS Gateway call signs, frequency used & distance in miles from your Grid Square location.

#### Verify a radio connection - wl2kax25 test

```bash
wl2kax25 -c <some_RMS_Gateway_callsign>
# or
wl2kax25 -c <some_RMS_Gateway_callsign> <some_digipeater>
```
