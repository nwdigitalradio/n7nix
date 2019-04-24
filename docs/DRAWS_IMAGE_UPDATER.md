## How to update an existing image

### Get the lastest script versions

* Get the current version of the image updater scripts.

```
cd
cd n7nix
git pull
```

### How to update Xastir only

* First read notes from Xastir wiki [If you already installed the binary version](http://xastir.org/index.php/HowTo:Raspbian)
  * Describes how to save your maps

* The _xs_verchk.sh_ script lives in directory ```n7nix/xastir```
```
cd
cd n7nix/xastir
# Run updater for Xastir only
./xs_verchk.sh -u
```
#### xs_verchk.sh options

* ```-h```list all the command line arguments for this script

```
./xs_verchk.sh -h
Usage: xs_verchk.sh [-u][-l][-h]
    No arguments displays current & installed versions.
    -u Set application update flag.
       Update source, build & install.
    -l display local version only.
    -h display this message.
```
* ```-u``` check the currently installed version against version in source repository and update from source repository if they are different.
  * Builds & installs the updated source.

```
./xs_verchk.sh -u
xastir: Running current version 2.1.1
```
* ```-l``` list the currently installed version of Xastir
```
./xs_verchk.sh -l
xastir: 2.1.1
```
* ```no command line arguments``` display currently installed version & latest version in source repository.
```
./xs_verchk.sh
xastir: current version: 2.1.1, installed: 2.1.1
```

### How to update all programs

The updater program ```~/bin/prog_refresh.sh``` is a script that
checks the local binary version of the program with the source version
located in some repository. It was initially intended to save time
when ever a new micro SD card image was being built. Specifically the
programs on the image that are built from source take a **long** time
to build!

* This script:
  * updates draws-manager web program
  * updates local bin directory
  * updates all HF HAM programs
  * updates Xastir from source repository
  * updates GPSD from source repository
  * checks for conflicting AudioSense-Pi driver

The _prog_refresh.sh_ script starts out by executing:
```
sudo apt-get -qq update
sudo apt-get -q -y upgrade
```

* At this time (Q1 2019 Linux kernel version 4.14.xx) when you do an
```apt-get upgrade``` the AudioSense-Pi driver prevents the DRAWS
tlv320aic32x4 driver from running.
  * You must run the _chk_conflict.sh_ script to enable the DRAWS audio driver
  * The _prog_refresh.sh_ script always runs this script.
```
chk_conflict.sh
```
* If the script determines _FLdigi_ needs to be upgraded, it checks if there is enough swap space.
  * If there is insufficient swap space allocated then the script will edit _/etc/dphys-swapfile_ and continue running.
  * You will probably not see the message due to the volume of console output.
  * To verify this happened run the ```swapon``` command before & after you run the _prog_refresh.sh_ script.
    * If the SIZE changed then:
```
# Either run this script again
prog_refresh.sh

# or for a quicker method

cd  ~n7nix/hfprogs
./hf_verchk.sh -u
```
#### prog_refresh.sh options

* ```-h```list all the command line arguments for this script

```
prog_refresh.sh -h
Usage: prog_refresh.sh [-u][-l][-h]
    No args will update all programs.
    -c displays current & installed versions.
    -l display local version only.
    -u update HAM programs only.
    -h display this message.
```

* ```-u``` option omits running ```apt-get update & apt-get upgrade``` and will just refresh most of the ham programs from source.
* ```-c``` option displays current version from a repository & installed version.
  * This is also the list of programs currently maintained from source.

```
prog_refresh.sh -c
js8call: current version: 1.0.0, installed: 1.0.0
wsjtx:   current version: 2.0.1, installed: 2.0.1
Library: libflxmlrpc IS loaded.
flxmlrpc:  current version: 0.1.4, installed: 0.1.4
fldigi:  current version: 4.1.02, installed: 4.1.02
flrig:  current version: 1.3.43, installed: 1.3.43
flmsg:  current version: 4.0.8, installed: 4.0.8
flamp:  current version: 2.2.04, installed: 2.2.04
xastir: current version: 2.1.1, installed: 2.1.1
gpsd: current version: 3.18.1, installed: 3.18.1
```

*```-l``` option displays the local versions of programs only.
```
prog_refresh.sh -l
js8call: 1.0.0
wsjtx: 2.0.1
fldigi: 4.1.02
flrig: 1.3.43
flmsg: 4.0.8
flamp: 2.2.04
Library: libhamlib IS loaded.
hamlib: 3.3
Library: libflxmlrpc IS loaded.
flxmlrpc: 0.1.4
xastir: 2.1.1
gpsd: 3.18.1
```