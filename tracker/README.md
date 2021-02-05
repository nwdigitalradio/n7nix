## Notes for nixtracker install
* Everything mentioned below in __Setup__ section is handled in install script _tracker_install.sh_

### Notes:
##### DRAWS RPi hat
* Third panel, __gps stats__, will not work until the following configs are defined in the tracker config file (aprs_tracker.ini):
  * This is true for any gpsd supported GPS device.
  * [gps] port
  * [gps] rate

### Setup
* copy these files to `/usr/local/bin`
```
aprs
```

* copy these files to `/etc/tracker`
```
apr_tracker.ini
```

* copy these files to `/home/<user>/bin`
```
aprs
aprs.ini
aprstest.ini
iptable-up.sh
iptable_notes.txt
set-udrc-thf6.sh
set-udrc-tmv71.sh
tracker
tracker-down
tracker-restart
tracker-up
```
* copy these files to `/home/<user>/bin/webapp`
```
acidTabs.js
favicon.ico
images
jQuery
styles.css
tracker-frontend.js
tracker-server.js
tracker.html

```

* copy this file to `/etc/systemd/system`
```
tracker.service
```
* then enable systemd service file
```
systemctl enable tracker.service
```

### Test & Verify

##### screen consoles
* screen config file is installed to /home/<user>/bin/.screenrc.trk


```
su
screen -ls
screen -x <pid_of_screen>
```

###### web page
```
localhost:8081
```
