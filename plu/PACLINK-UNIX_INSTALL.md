# Linux paclink-unix install for UDRC

## Install core components for Raspberry Pi with a UDRC sound card

* This installation assumes you have already [installed core components](https://github.com/nwdigitalradio/n7nix/blob/master/docs/CORE_INSTALL.md)

## These notes describe how to install & configures the following:

* paclink-unix
* postfix
* dovecot
* mutt
* claws-mail

#### Mutt

* Mutt is a small but very powerful __text__ based mail client
* By default the mutt email client is installed & configured
* To learn more about mutt go [here](http://www.mutt.org/)
* mutt is used to verify your postfix/paclink-unix setup using the [n7nix/debug/chk_mail.sh script](https://github.com/nwdigitalradio/n7nix/blob/master/debug/chk_mail.sh)

#### Claws-mail

* Follow [these
instructions](https://github.com/nwdigitalradio/n7nix/blob/master/email/claws/README.md)
when running claws-mail for the first time
* claws-mail should have a desktop icon or can be accessed from Main Menu > Internet > Claws Mail


## paclink-unix executables

*  for more information from a console execute _man wl2ktelnet_, _man wl2kax25_ or _man wl2kserial_

###### wl2ktelnet
* Uses telnet protocol to connect to a Winlink Common Message Server (CMS) over the Internet.

###### wl2kax25
* Uses HAM radio to connect to a Radio Mail Server (RMS) to gateway to the Internet and connect to a CMS.

###### wl2kserial
* Nick n2qz, the founder of paclink-unix, developed wl2kserial to interface to an SCS-PTC-IIpro modem using PACTOR III.

## Install paclink-unix

### Start the Install Script

* __NOTE: If you are using a DRAWS micro SD card image the install has already been done__
  *  Please skip to [Start the Config Script](#start-the-config-script)

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

paclink-unix install should now be completed and is ready for configuration.

### Start the Config Script

* You will be required to enter the following:
  * For paclink-unix
    * callsign
    * Winlink password
  * For mutt
    * Real name (ie. Joe Blow)
  * For Postfix
    * Configure _General type of mail configuration:_ accept the default _Internet Site_, just hit ```<Enter>```
    * Configure _System mail name: accept the default name, just hit ```<Enter>```

##### A note about the winlink password required by paclink-unix
* If you are not yet a registered Winlink user, just hit enter when prompted for the Winlink password
  * You will receive the password later on in the process from winlink.org
  * Once you receive your password you will enter it manually in file _/usr/local/etc/wl2k.conf_
    * Set the _wl2k-password=_ line with your new password.
* [this link](https://winlink.org/user) has information on creating a Winlink account & getting a password.

* The paclink-unix configure script does not take long

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
## Verify paclink-unix configuration

### How to verify paclink-unix - wl2ktelnet
* Read the _wl2ktelnet_ manual page for reference
```
man wl2ktelnet
```

* Open claws-mail
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
* If you get the above message when running _wl2ktelnet_ then you need to edit the following file with a valid Winlink password.
  * Edit the _wl2k-password=_ line.

```
/usr/local/etc/wl2k.conf
```


### How to verify paclink-unix - wl2kax25

#### Find a nearby RMS Gateway near you - 2 methods

##### 1 - Use the winlink web site

* Go to http://winlink.org/RMSChannels
  * Click on the _Packet_ button & locate your area on the map

##### 2 - Run a script to interrogate winlink web services server
* run either of these two scripts found in your local bin directory ie. _/home/pi/bin_
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

* Run the rmslist.sh script to get a list of RMS Gateway callsigns, frequencies & distances
  * The first argument is an integer in miles, second is your grid square

```bash
./rmslist.sh <integer_distance_in_miles> <maidenhead_grid_square>
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
