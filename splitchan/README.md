# Split Channel Operation

* Control AX.25/Direwolf & pulse audio port setup with file: _/etc/ax25/port.conf_
* Script _split_ctrl.sh_ is used to configure & display channel status the other 3 scripts are legacy **only**

After installing split channel, Direwolf will be attached to left connector & port udr0. HF programs will attach to right audio channel.
ie. FLDigi will use pulseaudio directly.
 *  "Server String" for FLDigi configuration:
```
unix:/var/run/pulse/native
```

### Scripts

##### split_ctrl.sh
* Defaults to displaying status of Direwolf, pulseaudio & asound
* **NOTE:** only Direwolf on left connector has been tested
* Use _split_ctrl.sh left_ to install AX.25 Direwolf on left DRAWS connector
* Use _split_ctrl.sh -s_ to verify split channel configuration

```
Usage: split_ctrl.sh [-c <connector>][-s][-d][-h][left|right|off]
                  No args will show status of Direwolf, pulseaudio & asound
  left            ENable split channel, direwolf uses left connector
  right           ENable split channel, direwolf uses right connector NOT IMPLEMENTED
  off             DISable split channel
  -c right | left ENable split channel, use either right or left mDin6 connector.
  -s              Display verbose status
  -d              Set DEBUG flag
  -h              Display this message.
```

### The following 3 scripts are legacy only

* Legacy, **do not use**

##### split_status.sh
```
Usage: split_status.sh [-d][-h]
    -d switch to turn on verbose debug display
    -h display this message.
```

##### split_uninstall.sh
```
Usage: split_status.sh [-d][-h]
    -d switch to turn on verbose debug display
    -h display this message.
```

##### split_chan.sh

```
Usage: split_chan.sh [-c][-d][-h]
                  No args will toggle split channel state.
  -c              Set split channels, left connector for Direwolf.
  -d              Set DEBUG flag
  -s              Display split channel status
  -h              Display this message.
```

