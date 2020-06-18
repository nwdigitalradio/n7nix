## Manually start ARDOP processes in separate consoles

#### ardop start script

##### ardop_ctrl.sh start
* This verifys systemd service files
```
cd
cd n7nix/ardop
./ardop_ctrl.sh start
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
  -a <radio name> specify radio name (ic706 ic7300 kx2)
  -f | --force    Update all systemd unit files & .asoundrc file
  -d              Set DEBUG flag
  -h              Display this message.
```