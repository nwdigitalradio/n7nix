# Linux paclink-unix install for Raspberry Pi

* **NOTE: You might already have an RPi image with paclink-unix imap installed**
  * Check for any of these conditions:
    * If you have an NWDRxx Raspberry Pi image
    * If you installed everything at once using the _image_install.sh_ script.
    * If you have already run _app_install.sh plu_
  * __If__ any of these conditions apply __then__ paclink-unix is already installed and continue on to  [Start the Config Script](#start-the-config-script) section

## Install core components

* This installation assumes you have already [installed core components](https://github.com/nwdigitalradio/n7nix/blob/master/docs/CORE_INSTALL.md)


## Install paclink-unix & Dovecot

* The script, _./app_install.sh pluimap_ will install the following:
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
* When dialog box for configuring iptables-persistent pops up just hit enter for:
  * 'Save current IPv4 rules?'
  * 'Save current IPv6 rules?'

### Start the Install Script

* Execute the following script from the directory that scripts were cloned to.
  * Should be starting from your login home directory eg. /home/pi

```bash
cd n7nix/config
# should now be in directory ~/n7nix/config
# become root
sudo su
./app_install.sh plu
```
* Upon completion you should see:

```
paclink-unix with imap, install script FINISHED

app install (plu) script FINISHED
```

  __paclink-unix install should now be completed and is ready for configuration__

## Start the Config Script
* The instructions from this point on assume paclink-unix has been successfully installed as is the case if you are using the NWDRxx RPi image.
* There are two options for configuring paclink-unix:
  * Full configuration: __./app_config.sh plu__
  * Minimal configuration: __./app_config.sh plumin__
    * Configures mutt email client & postfix only

* You will be required to enter the following:
  * For paclink-unix
    * callsign
    * Winlink password
  * For mutt
    * Real name (ie. Joe Blow)
  * For Postfix
    * Configure _General type of mail configuration:_ accept the default _Internet Site_, just hit ```<Enter>```
    * Configure _System mail name: accept the default name_, just hit ```<Enter>```

##### A note about the winlink password required by paclink-unix
* If you are not yet a registered Winlink user, just hit enter when prompted for the Winlink password
  * You will receive the password later on in the process from winlink.org
  * Once you receive your password you will enter it manually in file _/usr/local/etc/wl2k.conf_
    * Set the _wl2k-password=_ line with your new password.
* [this link](https://winlink.org/user) has information on creating a Winlink account & getting a password.

* The paclink-unix configure script does not take long
  * Console commands follow for a full paclink-unix configuration

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

# How to Verify paclink-unix configuration

###### Sending mail is a two step process
* Compose an email with your email app
* Send the email with paclink-unix using _wl2ktelnet_ or _wl2kax25_

###### Receiving mail is a two step process
* Get email using paclink-unix
* Reading an email with your email app

### Installed email clients
* Choose one of these email clients

#### Mutt

* Mutt is a small but very powerful __text__ based mail client
* By default the mutt email client is installed & configured
* To learn more about mutt go [here](http://www.mutt.org/)
* mutt is used to verify your postfix/paclink-unix setup using the [chk_mail.sh](https://github.com/nwdigitalradio/n7nix/blob/master/debug/chk_mail.sh) script.

#### Claws-mail

* Follow [these instructions](https://github.com/nwdigitalradio/n7nix/blob/master/email/claws/README.md)
when running claws-mail for the first time
* claws-mail should have a desktop icon or can be accessed from Main Menu > Internet > Claws Mail

#### Rainloop
* Follow [these instructions](https://github.com/nwdigitalradio/n7nix/blob/master/email/rainloop/README.md) when running Rainloop for the first time.
* Rainloop is a web base email client & can be accessed from a browser on your local RPi
  * __<your_local_ip_address>__
  * localhost

### First verify paclink-unix via Internet: wl2ktelnet
* Read the _wl2ktelnet_ manual page for reference
```
man wl2ktelnet
```

* Open claws-mail or your preferred email application
  * There should be a claws-mail desktop icon or can be accessed from Main Menu > Internet > Claws Mail
* Compose an email & address it to both of the following:
  * <your_callsign>@winlink.org
  * <your_regular_email_address>
* Be sure to fill in the Subject line
* Click __Send__

* You should now have a file waiting to be sent via Winlink in your Winlink __OUTBOX__
  * Winlink outbox location:  _/usr/local/var/wl2k/outbox_
  * Verify by running _chk_perm.sh_
  * Last line should read "1 files in outbox"

##### Run wl2ktelnet
* Now send the message by running _wl2ktelnet_ in a console.
  * Default parameters for wl2ktelnet should be sufficient
    * __NOTE:__ Do __NOT__ run this command as root.

```bash
wl2ktelnet
```
* Verify that there are no files in the Winlink __OUTBOX__
  * Run _chk_perm.sh_ again
  * Last line should read "No files in outbox"

* Run _wl2ktelnet_ again & look in your claws-mail __INBOX__
  * You should find the email you just sent
* Look in your regular email __INBOX__ you should find the same email.


###### Bad Winlink Password Symptom
```
wl2ktelnet: <*** [1] Secure login failed - account password does not match. - Disconnecting (207.32.162.17)
wl2ktelnet: unrecognized command (len 94): /*** [1] Secure login failed - account password does not match. - Disconnecting (207.32.162.17)/
```
* If you get the above message when running _wl2ktelnet_ then you need to edit this file: ```/usr/local/etc/wl2k.conf``` with a valid Winlink password.
  * Edit the line containing _wl2k-password=_




### Verify paclink-unix using your radio: wl2kax25

#### Find a nearby RMS Gateway near you - 2 methods

##### 1 - Use the winlink web site

* Go to http://winlink.org/RMSChannels
  * Click on the _Packet_ button & locate your area on the map

##### 2 - Run a script to interrogate winlink web services server
* run either of these two scripts found in your local bin directory ie. _/home/pi/bin_
  * gatewaylist.sh
  * rmslist.sh
* Both of these scripts will give similar output in different formats

###### Script: gatewaylist.sh
```bash
gatewaylist.sh
```
* defaults set a distance of 30 miles & GRID SQUARE cn88nl
  * If you edit the script run the _-l_ option to build a new list
* requires both [cURL](https://curl.haxx.se/) and the json parsing utility [jq](https://stedolan.github.io/jq/)
* Edit the _GRIDSQUARE=_ line at the top of the script with your gridsquare
* _-m `<miles>`_ sets the distance in miles of local RMS stations
* _-c_  gives a count of local stations found
* _-l_  build a new RMS station proximity list
* _-h_  lists all command line arguments

###### Script: rmslist.sh

* Run the rmslist.sh script to get a list of RMS Gateway callsigns, frequencies & distances
  * The first argument is an integer in miles, second is your grid square

```bash
rmslist.sh <integer_distance_in_miles> <maidenhead_grid_square>
```
* defaults set a distance of 30 miles & GRID SQUARE cn88nl
* requires both _cURL_ and the json parsing utility _jq_
  * If run as root will install both packages automatically
* Displays a list of RMS Gateway call signs, frequency used & distance in miles from your Grid Square location.
* For example:

```
rmslist.sh 40 CM96BX
Proximity file is: 0 hours 8 minute(s), 14 seconds old
Using distance of 40 miles & grid square CM96BX

  Callsign       Frequency  Distance    Baud
 K6BJ-11   	 145710000	5	9600
 W6TUW-10  	 144910000	5	1200
 K6BJ-10   	 145010000	10	1200
 KE6AFE-10 	 145630000	10	1200
 WB6RJH-10 	 145690000	14	1200
 KF6GPE-10 	 145630000	20	1200
 K2RDX     	  14107500	24	 600
 K2RDX-10  	 145630000	24	1200
 WA6LIE-10 	 145690000	24	1200
```


### Verify a radio connection - wl2kax25 test

* Read the _wl2kax25_ manual page for reference
```
man wl2kax25
```
##### Run wl2kax25
  * __NOTE:__ Do __NOT__ run this command as root.

```bash
wl2kax25 -c <some_RMS_Gateway_callsign>
# or
wl2kax25 -c <some_RMS_Gateway_callsign> <some_digipeater>

# For example
wl2kax25 -c w6tuw-10
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

## Test PLU web interface

### Test webapp

* nodejs & the paclink-unix web app are started automatically with systemd
* Check that systemd started the web app
  * as login user (ie. pi) run the following:

```
pluweb-status
```
* Verify that _active (running)_ is displayed

* There are also 2 commands to start & stop the node.js paclink-unix web app

```
pluweb-stop
pluweb-start
```

* In order to continuously view the web app log you need to execute the following as root:

```
sudo su
journalctl -f -u pluweb.service
```

* Now open a browser & enter either of these 2 URLs
  * __<your_local_ip_address>__:8082
  * localhost:8082

* You should now see something like the following:

---

![plu](images/pluwebcapture.png)

---
* Click on the _Outbox_ button

# Configure a mail client

## [mutt or Neomutt email client](https://www.neomutt.org/)
* mutt is configured by default in the  [mutt install script](https://github.com/nwdigitalradio/n7nix/blob/master/plu/mutt_install.sh)
  * **NOTE:** mutt is installed by default when paclink-unix is installed.

## [K-9 Mail Android client](https://k9mail.github.io/)
* Reference configuration for K-9 Mail

### Fetching mail

#### Incoming server

* IMAP server: 10.0.42.99
* Security: SSL/TLS
* Port: 993
* Username: <login_user_name>
* Authentication: Normal password
* Password: <login_password>

### Sending mail

#### Outgoing server

* SMTP server: 10.0.42.99
* Security: SSL/TLS
* Port: 465
* Require sign-in: check mark
* Username: <login_user_name>
* Authentication: Normal password
* Password: <login_password>

# Configure WiFi for remote operation

* __Under development__, not ready for use

* For host access point you will be required to enter:
  * SSID (eg. ham)

### Note: you will also have to run the hostap/fixed_ip.sh script
* You **MUST** read this script first to set up your fixed ip addresses for both eth0 & wlan interfaces.
* You **MUST** reboot after running the hostap/fixed_ip.sh script

###### Associate your device running your email client to the RPi WiFi Access Point
* Find the list of WiFi Access Points & select the one on the RPi
  * Look for the name you entered during configuration:

```
Enter Service set identifier (SSID) for new WiFi access point, followed by [enter]:
```
