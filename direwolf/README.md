# Direwolf installation files

###### config.sh
* direwolf is normally installed as part of the [core installation.](https://github.com/nwdigitalradio/n7nix/blob/master/docs/CORE_INSTALL.md)
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
Installed as part of the [core
install.](https://github.com/nwdigitalradio/n7nix/blob/master/docs/CORE_INSTALL.md)

### How to watch received packets

* Since direwolf is run as a daemon all standard output goes to the log file here:

```
/etc/direwolf/direwolf.log
```

* To watch the contents of this file as it changes:

```bash
tail -f /var/log/direwolf/direwolf.log
```

* The above command will let you see everything that would be sent to
the console if direwolf was started in a console instead of as a daemon by systemd.

* This log file gets rotated about once a day so you may have to
restart the _tail_ command if you leave it running for longer than a day.

### How to change what is output to logfile
* References to __Dire Wolf User Guide__ are for Version 1.4 -- April 2017
* To change command line options you need to edit the following file as root:
  *  /etc/systemd/system/direwolf.service
  * Look for this line in the file:

```
ExecStart=/usr/bin/direwolf -t 0 -c /etc/direwolf.conf -p
```

* In the __Dire Wolf User Guide__ look for section 9.15 Command Line Options around page 107

```
-d x   Debug options
   a = AGWPE network protocol client
   k = KISS serial port client
   n = KISS network client
   u = Redisplay non-ASCII characters in hexadecimal
   p = Packet hex dump
   g = GPS interface
   t = Tracker beacon
   o = Output controls such as PTT and DCD
   i = IGate
   h = Hamlib verbose level. Repeat for more.
   m = monitor heard station list.
   f = packet filtering. Use ff for details of individual filter specifications.
```
* For example to show packets being sent to the APRS TIER 2 server
  * Edit the /etc/systemd/system/direwolf.service file by adding the _-di_ option like this:

```
ExecStart=/usr/bin/direwolf -di -t 0 -c /etc/direwolf.conf -p
```

* From the same page also check the suppress output options.

```
-q x Quiet (suppress output) options
   h = Omit the _heard_ line with audio level.
   d = Omit decoding of APRS packets.
```

* You could also set LOGDIR in /etc/direwolf.conf
  * See Section 9.3 Logging of received packets
    * page 67 of __Dire Wolf User Guide__
  * Also Section 9.14 Logging on page 104

**NOTE:** if you change the config file or the command line options you will have to restart direwolf to make the new options take effect.

```
cd ~/bin
# Should be in directory /home/pi/bin
# Now become root
sudo su
./ax25-stop
./ax25-start

# Check that everything is running
./ax25-status
```

### How to refresh a previously cloned repository

* If you need to refresh your previously cloned n7nix repository in order to pick up the latest files do the following.
  * As user pi, **NOT** root

```bash
cd
cd n7nix
git pull origin master

# Verify update.sh is in the direwolf directory
ls direwolf
```

* You can now run the _update.sh_ script as root:

```bash
cd  direwolf
sudo su
./update.sh
```
