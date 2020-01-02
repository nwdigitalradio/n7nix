## Linux RMS Gateway Daily Log via Email

#### Operation

The RMS Gateway Daily log has 2 components, a report generater script & and an email sending script.

#### Setup

##### Copy files
Copy the required scripts to your local bin directory
```
cd
cp n7nix/debug/gwcron* ~/bin
```
##### Configure a transport

* This will determine what the crontab entry looks like.
* You have 3 choices for a transport:
  * Winlink via telenet
    * Default, uses wl2ktelnet in _gwcrondaily_wl2k.sh_ script
  * Winlink via RMS Gateway using a radio
    * Uses wl2kax25 in _gwcrondaily_wl2k.sh_ script
    * Edit _gwcrondaily_wl2k.sh_ script to include a valid RMS Gateway callsign
    * Uncomment wl2ktransport line that includes wl2kax25
  * Regular SMTP email
    * Uses _gwcrondaily_smtp.sh_ script
    * Edit _SENDTO_ variable in _gwcrondaily_smtp.sh_
      * Example _SENDTO_ assignment depending on whether you send email via your ISP or are running a local email server
```
SENDTO="bob@gmail.com"
SENDTO="gunn@beeble.localnet"
```

##### Create a crontab entry

```
crontab -e
```
* To email a report daily cut & paste this line to the bottom of the crontab file
  * Must use either _gwcrondaily_smtp.sh_ or _gwcrondaily_wl2k.sh_ depending on choosen transport.
  * The following example sends a report daily at 1 AM.
```
0 1 * * * /home/pi/bin/gwcrondaily_smtp.sh
```

##### Report generation

The report generator script, _gwcron.sh_ is called by the email
sending script, either _gwcrondaily_smtp.sh_ or _gwcrondaily_wl2k.sh_
. You can run the _gwcon.sh_ script at any time after copying to your local bin
directory.


```
gwcron.sh
```

* Output will look something like the following. Edit script
_/home/pi/bin/gwcron.sh_ to suite your needs.


```
### Thu 02 Jan 2020 08:24:46 AM PST Test Message from N7NIX-10
gwcron.sh: Found rotated log file!

1 logins and 1 logouts on Jan  1
100% connection success.

List of Stations that logged in:
KA7WYR

CPU temperature & throttle check
temp=56.4'C
throttled=0x0

Uptime:  08:24:46 up 21:27,  4 users,  load average: 0.88, 0.50, 0.42

/dev/root 15G 5.2G 8.6G 38% /

local ip addr: 10.0.42.85
```

#### Testing

* From a console run _gwcron.sh_ script to verify daily log output
* From a console run ```_gwcroncrondaily_<transport>.sh_``` script to verify that email is working
  * Use the wl2ktelnet transport in _gwcroncrondaily_wl2k.sh_ as that is the easiest to set up.
  * Look in mail log file _/var/log/mail.log_ for proper _relay=_ entry.
* To verify crontab also look in file _/var/log/mail.log_ for the log time that you set in your crontab entry, ie. 1 AM.
