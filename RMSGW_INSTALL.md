# Linux RMS Gateway install for UDRC

## Install core components

[Install core instructions](CORE_INSTALL.md)

## Install & configure RMS Gateway

* What remains is the  configuration of RMS Gateway
* You will be required to supply the following:
  * Your callsign
  * SSID used for RMS Gateway (recommend 10)
  * City name where gateway resides
  * State or province where gateway resides (recommend abbreviation)
  * Gridsquare of gateway's location
  * Winlink Gateway password

* Execute the following script.
```bash
./app_install.sh
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
