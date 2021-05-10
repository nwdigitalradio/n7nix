## To install & control rigctld-wsjtx for use with WSJT-X & JS8CALL

* The _wsj_ctrl.sh_ script sets up a systemd service file to load rigctld-wsjtx from boot.
* The 3 main functions of this script are _start_, _stop_ & _status_.
  * If the systemd unit file is not found it is created.
  * systemd unit file exists here: _/etc/systemd/system/rigctld-wsjtx.service_
  * _wsj_ctrl.sh_ script exists here: _~/n7nix/hfprogs/wsj_ctrl.sh_
* Radio defaults to ic706
  * To specify a different radio use '''-a''' option
  * ie. ```-a ic7000```
* You must edit the script to set the correct device name & baud rate of the rig control serial port.
  * Near the top of the script you see the following associative arrays with their element values.

```
rigctrl_device="/dev/ttyUSB0"

# names of supported radios
RADIOLIST="ic706 ic7000 ic7300 k2 k3 kx2 kx3"

# Rig numbers are from rigctl-wsjtx -l
declare -A radio_ic706=( [rigname]="IC-706" [rignum]=3011 [audioname]=udrc [samplerate]=48000 [baudrate]=4800 [pttctrl]="GPIO" [catctrl]="" [rigctrl]="-p 12" [alsa_lodriver]="-6.0" [alsa_pcm]="-26.5" )
declare -A radio_ic7000=( [rigname]="IC-7000" [rignum]=3060 [audioname]=udrc [samplerate]=48000 [baudrate]=19200 [pttctrl]="GPIO=12" [catctrl]="" [rigctrl]="" [alsa_lodriver]="-6.0" [alsa_pcm]="-16.5" )
declare -A radio_ic7300=( [rigname]="IC-7300" [rignum]=3073 [audioname]=CODEC [samplerate]=48000 [baudrate]=19200 [pttctrl]="/dev/ttyUSB0" [catctrl]="-c /dev/ttyUSB0" [rigctrl]="-p /dev/ttyUSB0 -P RTS" [alsa_lodriver]="-6.0" [alsa_pcm]="-16.5" )
declare -A radio_k2=( [rigname]="K2" [rignum]=2021 [audioname]=udrc [samplerate]=48000 [baudrate]=19200 [pttctrl]="GPIO=12" [catctrl]="" [rigctrl]="" [alsa_lodriver]="0.0" [alsa_pcm]="0.0" )
declare -A radio_k3=( [rigname]="K3" [rignum]=2029 [audioname]=udrc [samplerate]=48000 [baudrate]=19200 [pttctrl]="GPIO=12" [catctrl]="" [rigctrl]="" [alsa_lodriver]="0.0" [alsa_pcm]="0.0" )
declare -A radio_kx2=( [rigname]="KX2" [rignum]=2044 [audioname]=udrc [samplerate]=48000 [baudrate]=19200 [pttctrl]="GPIO=12" [catctrl]="" [rigctrl]="" [alsa_lodriver]="0.0" [alsa_pcm]="0.0" )
declare -A radio_kx3=( [rigname]="KX3" [rignum]=2045 [audioname]=udrc [samplerate]=48000 [baudrate]=19200 [pttctrl]="GPIO=12" [catctrl]="" [rigctrl]="" [alsa_lodriver]="0.0" [alsa_pcm]="0.0" )
```
* **Note:** The _rigctrl_device=_ and _[baudrate]=_ must match what your radio is expecting.
* **Note:** The IC-7300 uses an internal (to the radio) sound device all other radio entries use a DRAWS card.

* To verify parameters use ```-p```
  * For example:
```
 ./wsj_ctrl.sh -a ic706 -p
Setting radio name to: radio_ic706, rig name: IC-706

== Dump radio parameters for radio: radio_ic706
rig number: 3011, baud rate: 4800, audio device: udrc, alsa sample rate: 48000, ptt: GPIO, cat: , alsa pcm: -26.5
```

###### Usage output
```
./wsj_ctrl.sh -h
Usage: wsj_ctrl.sh [-a <name>][-f][-d][-h][status][stop][start]
                  No args will show status of rigctld-wsjtx
  -a <radio name> specify radio name (ic706 ic7000 ic7300 k2 k3 kx2 kx3)
  -f | --force    Update all systemd unit files
  -p              Print parameters for a particular radio name
  -d              Set DEBUG flag

                  args with dashes must come before following arguments

  start           start required rigctld-wsjtx process
  stop            stop all rigctld-wsjtx process
  status          display status of all rigctld-wsjtx process
  -h              Display this message.
```

###### -f option is used to force a refresh the systemd service file
* Using any of the 3 main commands add -f before command
  * For example:
```
./wsj_ctrl.sh -a kx2 -f status
```

#### Typical use:

##### Start systemd service file

* Only need to run ```./wsj_ctrl.sh start``` once.
  * This will set up the systemd service file that will be used if the RPi is ever rebooted.
  * For example

```
cd
cd n7nix/hfprogs
./wsj_ctrl.sh -a ic706 start

Setting radio name to: radio_ic706, rig name: IC-706
 == rigctld-wsjtx systemctl unit file check
Service: rigctld-wsjtx, status: 3
Systemd service files found
ENABLING rigctld-wsjtx
Created symlink /etc/systemd/system/multi-user.target.wants/rigctld-wsjtx.service  /etc/systemd/system/rigctld-wsjtx.service.
Starting service: rigctld-wsjtx
Service: rigctld-wsjtx, status: 0
```

##### After a reboot check the status of the running systemd service file

```
cd
cd n7nix/hfprogs
./wsj_ctrl.sh -a ic706 status

Setting radio name to: radio_ic706, rig name: IC-706

 == Status for configured rig: IC-706
 == rigctld-wsjtx systemctl unit file check
Service: rigctld-wsjtx, status: 0
Systemd service files found
 == rigctld-wsjtx process check
proc rigctld-wsjtx: 0, pid: 4286, args:  -m 3011 -r /dev/ttyUSB0 -s 4800 -P GPIO -p 12
  == audio device udrc check: state: RUNNING
```
