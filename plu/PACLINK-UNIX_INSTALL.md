# Linux paclink-unix install for UDRC

## Install core components for Raspberry Pi with a UDRC sound card

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

### Start the Install Script

* **NOTE: You might already have a Raspberry Pi SD card image with paclink-unix installed**
  * Check for any of these conditions:
    * If you installed everything at once using _image_install.sh_
    * If you already have run _app_install.sh pluimap_
    * If you have an image from SeaPac
  * Then continue on to  __Start the Config Script__ section

* Execute the following script from the directory that scripts were cloned to.
  * Should be starting from your login home directory for example on a Raspberry Pi _/home/pi_

```bash
cd n7nix/config
# should now be in directory ~/n7nix/config
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

### Start the Config Script

* This does not take long

```bash
cd n7nix/config
# should now be in directory ~/n7nix/config
# become root
sudo su
./app_config.sh plu
```

* When the script finishes you should see:

```
app config (plu) script FINISHED

```
## Verify the paclink-unix install

### Verify message composition

* As your normal login user (eg. pi, not root) compose an e-mail with your e-mail client
  * Next verify that a new file appears in _/usr/local/var/wl2k/outbox_

#### Verify Winlink telnet connection - wl2ktelnet test

* Default parameters for wl2ktelnet should be sufficient
  * As your login user (pi) execute:

```bash
wl2ktelnet
```
###### Bad Winlink Password Symptom
```
wl2ktelnet: <*** [1] Secure login failed - account password does not match. - Disconnecting (207.32.162.17)
wl2ktelnet: unrecognized command (len 94): /*** [1] Secure login failed - account password does not match. - Disconnecting (207.32.162.17)/
```
* If you get the above message when running _wl2ktelnet_ then you need to edit the following file with a valid Winlink password.
```
/usr/local/etc/wl2k.conf
```
* Edit the _wl2k-password=_ line.

### Find an RMS Gateway near you - 2 methods

##### 1 - Use the winlink web site

* Go to http://winlink.org/RMSChannels
  * Click on the _Packet_ button & locate your area on the map

##### 2 - Run a script to interrogate winlink web services server
* run either of these script found in your local bin directory ie. _/home/pi/bin_
  * gatewaylist.sh
  * rmslist.sh
* Both of these scripts will give similar output in different formats

###### gatewaylist.sh
```bash
./gatewaylist.sh
```
* defaults set a distance of 30 miles & GRID SQUARE cn88nl
  * If you edit the script run the _-l_ option to build a new list
* requires both the _cURL_ and the json parsing utility _jq_
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

### Verify a radio connection - wl2kax25 test

```bash
wl2kax25 -c <some_RMS_Gateway_callsign>
# or
wl2kax25 -c <some_RMS_Gateway_callsign> <some_digipeater>
```

##### Example console output of a Winlink radio connection

```
$ wl2kax25 -c ve7vic-10
Connected to AX.25 stack
Child process
wl2kax25: ---

wl2kax25: <WARA Winlink Node
wl2kax25: <[WL2K-3.2-B2FWIHJM$]
wl2kax25: sid [WL2K-3.2-B2FWIHJM$] inboundsidcodes -B2FWIHJM$
wl2kax25: <;PQ: 75494215
wl2kax25: Challenge received: 75494215
wl2kax25: <Perth CMS via VE7VIC >
wl2kax25: >[UnixLINK-0.5-B2FIHM$]
wl2kax25: >;PR: 12911535
wl2kax25: >; VE7VIC-10 DE N7NIX QTC 0
wl2kax25: >FF
wl2kax25: <FQ
Child process exiting
EOF on child fd, terminating communications loop.
Closing ax25 connection
Child exit status: 0
Waiting for AX25 peer ... timeout
```
