## Automatically start ARDOP processes using SYSTEMD Service Files

#### ardop start-up script

__NOTE:__ specify radio name with the _-a_ option see [below](#ardop_ctrlsh-script).

* The intention of the _ardop_ctrl.sh_ script was to get ARDOP running to be used with _ARIM_ or _PAT_ applications.
* If you haven't already installed PAT you should do that [now](https://github.com/nwdigitalradio/n7nix/tree/master/email/pat)

* This script does the following:
  * Stop draws-manager process (needed because PAT & draws-manager use the same port number)
  * Verify direwolf is NOT running (split_channel not supported at this time)
  * Create & enable systemd service files for rigctld, ardop & pat
  * Stop & disable systemd service files
  * Show detailed status of ardop/pat configuration.

* This script does __NOT__:
  * start ardop water fall
  * start _PAT_



##### ardop_ctrl.sh start
* This verifys systemd service files
```
cd
cd n7nix/ardop
./ardop_ctrl.sh start
```
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

##### ardop_ctrl.sh script

```
./ardop_ctrl.sh -h

Usage:  [-f][-d][-h][status][stop][start]
                  No args will show status of rigctld, piardopc, pat
                  args with dashes must come before other arguments
  start           start required ardop processes
  stop            stop all ardop processes
  status          display status of all ardop processes
  -a <radio name> specify radio name (ic706 ic7000 ic7300 kx2)
  -f | --force    Update all systemd unit files & .asoundrc file
  -d              Set DEBUG flag
  -h              Display this message.
```

##### Start ARDOP waterfall
* from a console:
```
piARDOP_GUI
```
