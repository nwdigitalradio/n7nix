## Packet Configuration Options

* For HAM apps that use AX.25 & _direwolf_

###### Running initcfg.sh script a second time will do the following:

  * Sets alsa parameters for a specific radio **<- this needs work**
  * Starts AX.25 & direwolf
  * Displays AX.25 status
  * Configures:
    * paclink-unix wl2kax25
    * postfix
    * dovecot
    * mutt, clawsmail, rainloop
    * lighttpd
  * Installs RPi temperature graph
  * Sets RPi LED to heartbeat

#### Other packet functionality supported

##### RMSGW


```bash
cd
cd n7nix/config
# Become root
sudo su
# If you want to run a Linux RMS Gateway
./app_config.sh rmsgw
```

#### APRS
* [APRX](https://github.com/nwdigitalradio/n7nix/tree/master/aprx)
* [Xaster](https://github.com/nwdigitalradio/n7nix/blob/master/xastir/README.md)
* [YAAC](https://github.com/nwdigitalradio/n7nix/tree/master/yaac)
* [nixtracker](https://github.com/nwdigitalradio/n7nix/tree/master/tracker)

##### Chattervox
* Follow [these instructions](https://github.com/nwdigitalradio/n7nix/blob/master/keyb2keyb/README.md)

##### uronode
* [Installation script](https://github.com/nwdigitalradio/n7nix/tree/master/uronode)

##### FBB bbs
* [Installation instructions](https://github.com/nwdigitalradio/n7nix/blob/master/bbs/README.md)