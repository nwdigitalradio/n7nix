## Notes for dantracker install
* Everything mentioned below is handled in install script tracker_install.sh

### Setup
* copy these files to /home/<user>/bin
```
aprs
aprs.ini
aprs_tracker.ini
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
* copy these files to /home/<user>/bin/webapp
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

* copy this file to /etc/systemd/system
```
tracker.service
```
* then enable systemd service file
```
systemctl enable tracker.service
```
