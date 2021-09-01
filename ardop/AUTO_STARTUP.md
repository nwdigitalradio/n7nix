## Automatically start ARDOP processes using SYSTEMD Service Files

#### ardop start-up script

__NOTE:__ specify radio name with the _-a_ option see [below](#ardop_ctrlsh-script). Default radio is Icom ic706.

* The intention of the _ardop_ctrl.sh_ script is to get ARDOP running to be used with _ARIM_ or _PAT_ applications.
* If you haven't already installed PAT you should do that [now](https://github.com/nwdigitalradio/n7nix/tree/master/email/pat)

* This script does the following:
  * Stop draws-manager process (needed because PAT & draws-manager use the same port number)
  * Verify direwolf is NOT running (split_channel not supported at this time)
  * _START:_ Create & enable systemd service files for rigctld, ardop & pat listener
  * _STOP:_ Stop & disable systemd service files
  * _STATUS:_ Show detailed status of ardop/pat configuration.

* This script does __NOT__:
  * start ardop water fall
  * start _PAT_


### ardop_ctrl.sh script

```
./ardop_ctrl.sh -h

Usage:  [-f][-d][-h][status][stop][start]
                  No args will show status of rigctld, piardopc, pat
                  args with dashes must come before other arguments
  start           start required ardop processes
  stop            stop all ardop processes
  status          display status of all ardop processes
  -a <radio name> specify radio name (ic706 ic7000 ic7300 k2 k3 kx2 kx3)
  -f | --force    Update all systemd unit files & .asoundrc file
  -d              Set DEBUG flag
  -h              Display this message.
```

* To force an update of the systemd service files use the _-f_ option which will update the following files:
  * Desktop/ardop-gui.desktop
  * rigctld systemd service file
  * piardopc systemd service file
  * pat listener systemd service file
* Use the _force_ option if the _ardop_ctrl.sh_ script is updated or you switch to a different radio.


##### ardop_ctrl.sh start
* Verify and start Systemd Service Files.
```
cd
cd n7nix/ardop
./ardop_ctrl.sh -a <radio name> start
```
* You __must__ specify the radio you are using
  * Defaults to ic706
* _ardop_ctrl.sh_ script does not do much auto editing
  * If you see the following _.asoundrc_ card number file check during startup
```
asoundrc_file_check: asound cfg device does NOT match aplay device
```
* then do the following and edit .asoundrc so that sound card numbers match in the ```pcm "hw:x,0"``` line
```
cat ~/.asoundrc
aplay -l
```

##### ardop_ctrl.sh stop

* Stop all Ardop systemd service files and Ardop processes
* This option will stop any Ardop processes that were started from a console or Systemd Service Files

##### Specify a radio
* Default radio is IC-706
* Example to change to IC-7300
```
cd
cd n7nix/ardop
./ardop_ctrl.sh -a ic706 stop
./ardop_ctrl.sh -f -a ic7300 start

 # Only have to use the -f force flag once to re-write the systemd
 #  unit files for a particular radio

./ardop_ctrl.sh -a ic7300 status
```
##### Systemd unit files exec commands for IC-7300
* For rigctld.service
```
ExecStart=/usr/local/bin/rigctld -m 373 -r /dev/ttyUSB0 -p /dev/ttyUSB0 -P RTS -s 19200
```
* For ardop.service
```
ExecStart=/bin/sh -c "/home/pi/bin/piardopc 8515 pcm.ARDOP pcm.ARDOP -c /dev/ttyUSB0 -p /dev/ttyUSB0"
```

#### Start ARDOP waterfall

##### To run waterfall from desktop icon
* If _piARDOP_GUI_ Desktop file does not exist it will get installed from either the ardop_install.sh or ardop_ctrl.sh

__NOTE:__ the Desktop file that is executed from this icon really needs an appropriate icon file.

* To get rid of annoying dialog box that prompts for what to do with an executable do the following:
  * File manager > Edit > Preferences > General
  * Check _Don't ask options on launch executable file_

##### To run waterfall from a console:
```
piARDOP_GUI
```

#### How to Use PAT: Brief Instructions

__NOTE:__ If _ardop_ctrl.sh_ script was executed the PAT listener should be running.

##### Verify PAT listener is running
```
cd
cd n7nix/ardop
./ardop_ctrl.sh status | grep -i pat
```
* Expected result:
```
Found program: pat, version: Pat v0.9.0 (f52df2f) linux/arm - go1.13.8
Service: pat, status: 0
proc pat: 0, pid: 408, args:  http
```

##### Compose a Winlink message
* To use PAT open a browser & use URL ```localhost:8080```

##### Send a Winlink message

* [Point-to-Point](https://github.com/nwdigitalradio/n7nix/blob/master/email/pat/README.md#winlink-point-to-point-connection)
* [Connect to an RMS Gateway](https://github.com/nwdigitalradio/n7nix/blob/master/email/pat/README.md#rms-gateway-winlink-connection)
