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

##### Test using rmsgw_aci & rmschanstat
* rmsgw_aci = Winlink gateway automatic check-in
* as rmsgw run rmsgw_aci & rmschanstat

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
##### channels.xml #####
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
### Sending daily RMS Gateway reports via email using CRON

* See [Sending System reports via Winlink using CRON](https://github.com/nwdigitalradio/n7nix/blob/master/debug/MAILSYSREPORT.md)
  * From the [debug repository](https://github.com/nwdigitalradio/n7nix/tree/master/debug)
