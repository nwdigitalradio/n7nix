# Direwolf installation files

###### install.sh
* direwolf is normally installed as part of the [core installation.](https://github.com/nwdigitalradio/n7nix/blob/master/CORE_INSTALL.md)
* This install script is called from the config/core_install.sh script.

###### callpass.c
* callpass.c is a file taken from Xastir to compute the pass code required to login to a Tier 2 APRS server.
* This file is built & called from the install script in this directory.

###### update.sh
* update.sh is a script that will replace the version of direwolf installed as a Debian package during core install.
* This script requires that you previously installed direwolf using the scripts found in this repository.
* _update.sh_ is meant to be run from the command line:
``` bash
sudo su
./update.sh
```

* After the script is run direwolf will be stopped.
* The last line on your console should be similar to below:
```
direwolf version was: 1.3 is now: Dire Wolf version 1.4 (Apr 27 2017) Beta Test
```

* To restart direwolf and other packet dependencies run the following:

```
cd ~/bin
sudo su
./ax25-stop
./ax25-start

# Check that everything started OK
./ax25-status
```

The scripts ax25-stop, ax25-start, ax25-status were previously
Installed part of the [core
install.](https://github.com/nwdigitalradio/n7nix/blob/master/CORE_INSTALL.md)