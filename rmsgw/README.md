# Linux RMS Gateway install for UDRC

## Install core components

* This installation assumes you have already [installed core components](https://github.com/nwdigitalradio/n7nix/blob/master/docs/CORE_INSTALL.md)

## Install RMS Gateway

* What remains is the  configuration of RMS Gateway
* You will be required to supply the following:
  * Your callsign
  * SSID used for RMS Gateway (recommend 10)
  * City name where gateway resides
  * State or province where gateway resides (recommend abbreviation)
  * Gridsquare of gateway's location
  * Winlink Gateway password
  * Radio frequency in Hz

### Start the Install Script

* **NOTE: You might already have an image with RMS Gateway installed**
  * Check for any of these conditions:
    * If you installed everything at once using _image_install.sh_
    * If you already have run _app_install.sh rmsgw_
    * If you have an image from SeaPac
  * Then continue on to  __Start the Config Script__ section

* Execute the following script from the directory that scripts were cloned to.
  * Should be starting from your login home directory eg. /home/pi

```bash
cd n7nix/config
# should now be in ~/n7nix/config
# become root
sudo su
./app_install.sh rmsgw
```
### Start the Config Script

* Execute the following script from the directory that scripts were cloned to.
  * Should be starting from your login home directory eg. /home/pi

```bash
cd n7nix/config
# should now be in directory ~/n7nix/config
# become root
sudo su
./app_config.sh rmsgw
```

* When the script finishes you should see:
```
app config rmsgw script FINISHED
```
* You are now ready to test the RMS gateway.
* Reboot your pi one more time login & verify the hostname changed
  * You should see your console prompt like this: pi@your_host_name:

```bash
# reboot
shutdown -r now
```

### Testing the RMS Gateway
* Get someone to connect to your callsign with SSID of 10 ie. your_callsign-10
* After a while you should see your callsign on the [Winlink map](http://winlink.org/RMSChannels)
  * Be sure to select *Packet*
  * On the top line in the map click the circle next to Packet
* To monitor the RMS Gateway debug log open a console window and type:
```bash
tail -f /var/log/rms.debug
```
* If you see this:
```
tail: cannot open '/var/log/rms.debug' for reading: No such file or directory
```
* on new installations the log file will be empty for up to 1/2 hour or so.

##### Test Winlink automatic check-in script
* rmsgw_aci = Radio Mail Server Gateway automatic check-in
* _rmsgw_aci_ is a C program that calls bash script _rmschanstat_

* To test these two programs run this script: ``` chk_wlaci.sh```
  * _chk_wlaci.sh_ can be found [in the n7nix repository](https://github.com/nwdigitalradio/n7nix/blob/master/rmsgw/chk_wlaci.sh) n7nix/rmsgw

###### chk_wlaci.sh script output example
```
==== Check stat directory
total 8
drwxr-xr-x 2 rmsgw rmsgw 4096 Dec  7  2019 .
drwxr-xr-x 4 rmsgw rmsgw 4096 Jan 22 10:11 ..
-rw-r--r-- 1 rmsgw rmsgw    0 Jul  8 14:42 .channels.udr0
-rw-r--r-- 1 rmsgw rmsgw    0 Jul  7 17:21 cms.winlink.org
-rw-r--r-- 1 rmsgw rmsgw    0 Jul  7 21:42 .version.N7NIX-10

==== Check rmsgw automatic check-in at Wed 08 Jul 2020 03:11:12 PM PDT
Using axports line: udr0            N7NIX-10        9600    255     2       2M Winlink
Using port: udr0, call sign: N7NIX-10
 Verify rmschanstat
channel udr0 with callsign N7NIX-10 on interface ax0 up
 Verify rmsgw_aci
channel udr0 with callsign N7NIX-10 on interface ax0 up

==== Check rmsgw crontab entry
14,42 * * * * /usr/local/bin/rmsgw_aci > /dev/null 2>&1


==== Check rmsgw log file
Jul  8 14:14:01 nixgatef rmsgw_aci[8727]: N7NIX-10 - Linux RMS Gateway ACI 2.5.1 Sep 19 2019 (CN88nl)
Jul  8 14:14:01 nixgatef rmsgw_aci[8727]: Channel: N7NIX-10 on udr0 (144910000 Hz, mode 0)
Jul  8 14:14:01 nixgatef rmsgw_aci[8727]: Channel Stats: 1 read, 1 active, 0 down, 0 updated, 0 errors
Jul  8 14:42:01 nixgatef rmsgw_aci[8852]: N7NIX-10 - Linux RMS Gateway ACI 2.5.1 Sep 19 2019 (CN88nl)
Jul  8 14:42:01 nixgatef rmsgw_aci[8852]: Channel: N7NIX-10 on udr0 (144910000 Hz, mode 0)
Jul  8 14:42:02 nixgatef updatechannel.py[8872]: Posting channel record updates for N7NIX-10...
Jul  8 14:42:03 nixgatef rmsgw_aci[8852]: Channel Stats: 1 read, 1 active, 0 down, 1 updated, 0 errors
Jul  8 15:11:46 nixgatef rmsgw_aci[9014]: N7NIX-10 - Linux RMS Gateway ACI 2.5.1 Sep 19 2019 (CN88nl)
Jul  8 15:11:46 nixgatef rmsgw_aci[9014]: Channel: N7NIX-10 on udr0 (144910000 Hz, mode 0)
Jul  8 15:11:46 nixgatef rmsgw_aci[9014]: Channel Stats: 1 read, 1 active, 0 down, 0 updated, 0 errors
==== chk_wlaci.sh finished at Wed 08 Jul 2020 03:11:46 PM PDT
```

__The following are historical notes for _rmgw_aci_ & _rmschanstat_ ONLY__

* as user rmsgw run rmsgw_aci & rmschanstat

* On Raspbian jessie the following works:
  * As of 1/1/2018 you have to modify the rmschanstat script if you are using Raspbian stretch
  * Look at this [Commit](https://github.com/nwdigitalradio/rmsgw/commit/b24c1a30e56326eb6edf868c86efe9ff4a8b7a25) for fix.
```
sudo -u rmsgw rmsgw_aci
channel udr0 with callsign KF7FIT-10 on interface ax0 up
#
sudo -u rmsgw rmschanstat ax25 udr0 KF7FIT-10
channel udr0 with callsign KF7FIT-10 on interface ax0 up
```
* On Raspbian stretch this fails because ifconfig output has changed between jessie & stretch

```
sudo -u rmsgw rmsgw_aci
status for interface ax0: unavailable
#
root@garkbit:/etc/rmsgw# sudo -u rmsgw rmschanstat ax25 udr0 KE7KML-10
status for interface ax0: unavailable
```
__End of historical notes__

##### FILE: channels.xml #####
* Used by rmschanstat.py & rmsgw_aci programs
* lives in this directory:
```
/etc/rmsgw
```
* Some versions of the _/etc/rmsgw/channels.xml_ file have the following for the first 2 lines:
```
<?xml version="1.0" encoding="UTF-8"?>
<rmschannels xmlns="http://www.w3sg.org/rmschannels"
```
* __This will not work__, it will prevent your station callsign from appearing on the Winlink:
  *  packet station map
  *  packet RMS List
* use the following instead:
  * Second line changes:
    * from: _http://www.w3sg.org/rmschannels_
    * to _http://www.namespace.org_
```
<?xml version="1.0" encoding="UTF-8"?>
<rmschannels xmlns="http://www.namespace.org"
```
### Changing AX.25 port
* Port currently defaults to ```udr1``` which is the right mDin6 connector on a DRAWS hat.
* To change the port to ```udr0```, the left port, modify the following files.
  * /etc/rmsgw/channels.xml
  * /etc/ax25/axports
  * /etc/ax25/ax25d.conf

### Sending daily RMS Gateway reports via email using CRON

* See [Sending System reports via Winlink using CRON](https://github.com/nwdigitalradio/n7nix/blob/master/debug/MAILSYSREPORT.md)
  * From the [debug repository](https://github.com/nwdigitalradio/n7nix/tree/master/debug)
