## PAT Quick Start Guide for AX.25 & ARDOP using scripts

* After
[installing](https://github.com/nwdigitalradio/n7nix/tree/master/email/pat#installing-pat)
PAT, run _listener_ctrl.sh_ to disable any paclink-unix listeners.

```
listener_ctrl.sh status

listener_ctrl.sh --del

listener_ctrl.sh status
```
* ```listener_ctrl.sh status``` output after ```listener_ctrl.sh --del ``` deletes paclink-unix listener entries in file _/etc/ax25/ax25d.conf_

```
 === PAT status
DEBUG:
pi        7989  0.0  0.3 879212 12888 ?        Ssl  Feb05   0:34 /usr/bin/pat --listen=ax25 http
end DEBUG
proc pat: 0, pid: 7989, args:  --listen=ax25 http

 === paclink-unix status
Daemon file: Total entries: 2, wl2kax25 entries: 0
[KF7FIT-10 VIA udr0]
NOCALL   * * * * * *  L
default  * * * * * *  - rmsgw /usr/local/bin/rmsgw rmsgw -P %d %U
[KF7FIT-10 VIA udr1]
NOCALL   * * * * * *  L
default  * * * * * *  - rmsgw /usr/local/bin/rmsgw rmsgw -P %d %U
```

* PAT is now __set up to run the AX.25 stack__

* To __switch to ARDOP protocol__ run the following:

```
pat_ctrl.sh stop
ardop_ctrl.sh start
ardop_ctrl.sh status
```

* ```ardop_ctrl.sh status``` output after running ```ardop_ctrl.sh start ```

```
Service: draws-manager is already stopped

 == Status for configured rig: IC-706
== Pulse Audio is running with pid: 783
asoundrc_file_check: Found ARDOP entry in /home/pi/.asoundrc
asoundrc_file_check: asound cfg device match: sound card number: 2
asoundrc_file_check: sample rate: 48000
File: /etc/asound.conf does not exist
 == Ardop Verify required programs
Found program: piARDOP_GUI
Found program: piardop2, ARDOPC Version 2.0.3.8-BPQ
Found program: piardopc, ARDOPC Version 1.0.4.1j-BPQ
Found program: arim, version: ARIM 2.12
Found program: pat, version: Pat v0.12.1 (ccb4934) linux/arm - go1.17.5
 == Ardop systemctl unit file check

Port 8080 IS IN USE by: pat

Service: rigctld, status: 0
Service: ardop, status: 0
Service: pat_listen, status: 0
All systemd service files found
 == Ardop process check
proc rigctld: 0, pid: 1601, args:  -m 3011 -r /dev/ttyUSB0 -s 4800
proc piardopc: 0, pid: 1627, args:  8515 pcm.ARDOP pcm.ARDOP -p GPIO=12
proc piARDOP_GUI: 1, NOT running
proc pat: 0, pid: 1690, args:  --listen=ardop http
  == audio device udrc check: state: RUNNING
Finished ardop status
```

* To __switch back to AX.25 protcol__ run the following:

```
ardop_ctrl.sh stop
pat_ctrl.sh start
pat_ctrl.sh status
```

* ```pat_ctrl.sh status``` output after running ```pat_ctrl.sh start```

```
Status for systemd service: draws-manager: NOT RUNNING and NOT ENABLED
 Status for systemd service: pat_listen: RUNNING and ENABLED
 proc pat: 0, pid: 2512, args:  --listen=ax25 http
 == Port 8080 in use by: pat
 == audio device udrc check: state: RUNNING
Finished pat ax.25 status
```