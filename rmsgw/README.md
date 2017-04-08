# Linux RMS Gateway install for UDRC

## Install core components

* This installation assumes you have already [installed core components](https://github.com/nwdigitalradio/n7nix/blob/master/CORE_INSTALL.md)

## Install & configure RMS Gateway

* What remains is the  configuration of RMS Gateway
* You will be required to supply the following:
  * Your callsign
  * SSID used for RMS Gateway (recommend 10)
  * City name where gateway resides
  * State or province where gateway resides (recommend abbreviation)
  * Gridsquare of gateway's location
  * Winlink Gateway password
  * Radio frequency in Hz

* Execute the following script as root from the directory scripts were cloned to.
```bash
cd n7nix/config
# should now be in ~/n7nix/config
# become root
sudo su
./app_install.sh rmsgw
```
* When the script finishes & you see *app install script FINISHED* you are ready to test the RMS gateway
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
