## Test programs for verifying DRAWS GPS module

### Get the lastest script versions

* Get the current version of the GPS test scripts.

```
cd
cd n7nix
git pull
```

### Test program gps_test.sh

* Requirement to be run in gps directory
  * Builds C program gp_testport.c

```
cd
cd n7nix/gps
./gps_test.sh
```
* The C program called from the script communicates through the serial port (/dev/ttySC0) to the GPS/GLONASS module on the DRAWS hat.

This program displays a spinner until the first satellite is viewed
then displays elapsed time since it started running until first
satellite viewed.

The min value displayed only means the first count of satellites that
the module saw as it was locking in. The interesting significance would
be if it ever gets to 0 when running for an extended period of time.

Program has been tested running from warm boot & cold boot with & without the
CR 1220 GPS battery. It seems like if the GPS has ever achieved satellite lock that
it only takes a couple of minutes at most to get there again after
warm/cold boot with/without battery.

* The spinner changes with each read from the _/dev/ttySC0_ serial port

* What the output looks like when running after a warm boot.

```
 ./gps_test.sh
Warning: Stopping gpsd.service, but it can still be activated by:
  gpsd.socket
Source file found, building
gcc -O2 -g -gstabs -Wall -I/usr/local/include -DLINUX   -c -o gp_testport.o gp_testport.c
gcc gp_testport.o -o gp_testport
Running in sat count mode
Wed Apr 24 12:53:40 2019,  wait for first satellite view
14 seconds until first sat view
sats: 13, min:  4, max: 13
```

* What the output looks like when stopped with ctrl c

```
./gps_test.sh
Warning: Stopping gpsd.service, but it can still be activated by:
  gpsd.socket
Source file found, building
gcc -O2 -g -gstabs -Wall -I/usr/local/include -DLINUX   -c -o gp_testport.o gp_testport.c
gcc gp_testport.o -o gp_testport
Running in sat count mode
Wed Apr 24 12:53:40 2019,  wait for first satellite view
14 seconds until first sat view
^Cts: 12, min:  4, max: 13
Exiting script from trapped CTRL-C
Cleaning up & starting gpsd
Service gpsd already enabled
```
* What the output looks like from consecutive runs. There is no delay for
first satellite view.

```
./gps_test.sh
Warning: Stopping gpsd.service, but it can still be activated by:
  gpsd.socket
Source file found, building
gcc -O2 -g -gstabs -Wall -I/usr/local/include -DLINUX   -c -o gp_testport.o gp_testport.c
gcc gp_testport.o -o gp_testport
Running in sat count mode
Wed Apr 24 13:04:31 2019,  wait for first satellite view
sats: 10, min:  8, max: 11
```
