# DEBUG notes
#####  Collection of notes & scripts that might help solve problems

#### Contents

1. Cronjob & scripts to email daily System reports using Winlink
2. Cronjob & scripts to email daily RMS Gateway reports using Winlink or SMTP
3. Enable the serial console on an RPi 3
4. Push-to-Talk GPIOs used by an UDRC, UDRC II & DRAWS
5. Direwolf/UDRC - test output channels & push to talk
6. How to capture everything you typed on a console
7. Some scripts to display useful information for debug

## [1. EMail daily reports using Winlink](https://github.com/nwdigitalradio/n7nix/blob/master/debug/MAILSYSREPORT.md)

* Use 3 scripts to:
  * Generate a report
  * Email report
  * Check outbox for files to send

## [2. EMail daily RMS Gateway reports using Winlink or SMTP](https://github.com/nwdigitalradio/n7nix/blob/master/debug/MAILGATEWAYLOGIN.md)

* Use 3 scripts to:
  * Generate a report
  * Email report
  * Check outbox for files to send

## 3. Enable serial console
* Enabling the serial port on a Raspberry Pi 3 will **disable** bluetooth
* In file /boot/config.txt add
```
dtoverlay=pi3-disable-bt
```
* In file /boot/cmdline.txt change
```
console=serial0,
```
* to
```
console=ttyAMA0,115200
```


## 4. PTT Push to Talk & RPi GPIOs
* These are the GPIO numbers to use in direwolf.conf
  * ie. for Channel 1 Properties
```
CHANNEL 1
PTT GPIO 23
MODEM 1200
```


| device  |  chan 0    |   chan 1    |
|---------|------------|-------------|
| UDRC    |  12 both   |   12 both   |
| UDRC II |  12 HD15   |   23 mDIN6  |
| DRAWS   |  12 mDIN6  |   23 mDIN6  |

## 5. Direwolf/UDRC testing

### Test output & Push to Talk

#### Using beacon test

* Tune your radio to APRS frequency 2M 144.390 MHz.

```bash
cd n7nix/debug
sudo su
./btest.sh
```

* Requires Direwolf to be running
* Constructs a vaild message beacon with day of month & time (hrs, min, sec)
* Check aprs.fi, click on "raw packets", set "originating callsign:" to your callsign followed by an asterisk (your_callsign*)
  * If you are transmitting you will see your message & who gated it to the Internet.
```
2017-05-01 13:42:21 PDT: N7NIX-11>APUDR1,WIDE1-1,qAR,AF7DX-1::N7NIX-1  :01 13:42:16 PDT N7NIX beacon test from host check_test8
```

#### Using gpio, sox & aplay

* Requires direwolf to **NOT** be running
  * If you installed direwolf with the n7nix scripts then stop direwolf like this:
```bash
cd
cd bin
sudo su
./ax25-stop

# to restart direwolf
./ax25-start
```
* Use the _measure_deviate.sh_ script found in [this repository](https://github.com/nwdigitalradio/n7nix/tree/master/deviation)

#### Using speaker-test

* Requires direwolf to **NOT** be running
* speaker-test - command-line speaker test tone generator for ALSA
  * From Paul Johnson ve7dhm use [speaker-test](https://linux.die.net/man/1/speaker-test)
    * When you key the radio you should hear a tone using another radio as a monitor doing the following:
```
speaker-test -Dplughw:udrc -c2 -f1200 -tsine -l0
```
* This gives a looping on/off 1200 HZ tone

## 6. Capture everything typed on the console

* This program will capture everyting you type on a console
  * When you are done, type exit

```bash
script logfilename.txt
```
then at the end of a session run:

```bash
exit
```

* Now there will be a history of everything typed in the whatever file name you gave to logfilename.

## 7. Scripts to display useful information

#### sysver.sh

```
~/bin$ ./sysver.sh
----- /proc/version
Linux version 4.4.39-v7+ (jenkins@belvedere) (gcc version 5.4.0 20160609 (Ubuntu/Linaro 5.4.0-6ubuntu1~16.04.4) ) #1 SMP Sat Apr 22 14:29:44 PDT 2017
----- /etc/*version
8.0
----- /etc/*release
PRETTY_NAME="Raspbian GNU/Linux 8 (jessie)"
NAME="Raspbian GNU/Linux"
VERSION_ID="8"
VERSION="8 (jessie)"
ID=raspbian
ID_LIKE=debian
HOME_URL="http://www.raspbian.org/"
SUPPORT_URL="http://www.raspbian.org/RaspbianForums"
BUG_REPORT_URL="http://www.raspbian.org/RaspbianBugs"
----- lsb_release
No LSB modules are available.
Distributor ID: Raspbian
Description:    Raspbian GNU/Linux 8.0 (jessie)
Release:        8.0
Codename:       jessie
---- systemd
   Static hostname: check_test8
         Icon name: computer
           Chassis: n/a
        Machine ID: 5383aa1d293048eebe8526d433a7ae1a
           Boot ID: a1e56074e8504cab8d798ad006941245
  Operating System: Raspbian GNU/Linux 8 (jessie)
            Kernel: Linux 4.4.39-v7+
      Architecture: arm
----- direwolf
 ver: Dire Wolf version 1.3
```


#### udrcver.sh

```
 ./udrcver.sh
Found an original UDRC
     HAT ID EEPROM
Name:        hat
Product:     Universal Digital Radio Controller
Product ID:  0x0002
Product ver: 0x0003
UUID:        2299237d-dad5-433b-afce-5509de8ebbe8
Vendor:      NW Digital Radio
````

#### piver.sh

```
 ./piver.sh
 Pi 3 Model B Mfg by Embest
 Has WiFi
```

#### sndcard.sh

```
./sndcard.sh
udrc card number line: card 0: udrc [udrc], device 0: Universal Digital Radio Controller tlv320aic32x4-hifi-0 []
udrc is sound card #0
```

#### ax25-status
* Note hciuart.service listed below failed to load because I purposed the serial port for a serial console.
  * Bluetooth & the serial console are either/or for the RPi 3

```
~/bin $ ./ax25-status
== failed & loaded but inactive units==
  UNIT            LOAD   ACTIVE SUB    DESCRIPTION
* hciuart.service loaded failed failed Configure Bluetooth Modems connected by UART

LOAD   = Reflects whether the unit definition was properly loaded.
ACTIVE = The high-level unit activation state, i.e. generalization of SUB.
SUB    = The low-level unit activation state, values depend on unit type.

1 loaded units listed.
To show all installed unit files use 'systemctl list-unit-files'.

== direwolf ==
  pid: 523
  ver: Dire Wolf version 1.3
== /proc/sys ==
ax25  core  ipv4  ipv6	netfilter  nf_conntrack_max  unix
ax0

== ifconfig ax0 ==
ax0       Link encap:AMPR AX.25  HWaddr N7NIX-2
          inet addr:44.24.197.66  Bcast:44.255.255.255  Mask:255.255.255.255
          UP BROADCAST RUNNING  MTU:255  Metric:1
          RX packets:18 errors:0 dropped:0 overruns:0 frame:0
          TX packets:5 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:10
          RX bytes:1413 (1.3 KiB)  TX bytes:20 (20.0 B)


== status networkd services ==
enabled
● systemd-networkd-wait-online.service - Wait for Network to be Configured
   Loaded: loaded (/lib/systemd/system/systemd-networkd-wait-online.service; enabled)
   Active: active (exited) since Mon 2017-05-01 15:48:47 PDT; 1min 44s ago
     Docs: man:systemd-networkd-wait-online.service(8)
  Process: 546 ExecStart=/lib/systemd/systemd-networkd-wait-online (code=exited, status=0/SUCCESS)
 Main PID: 546 (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/systemd-networkd-wait-online.service
enabled
● systemd-networkd.service - Network Service
   Loaded: loaded (/lib/systemd/system/systemd-networkd.service; enabled)
   Active: active (running) since Mon 2017-05-01 15:48:46 PDT; 1min 44s ago
     Docs: man:systemd-networkd.service(8)
 Main PID: 503 (systemd-network)
   Status: "Processing requests..."
   CGroup: /system.slice/systemd-networkd.service
           |_503 /lib/systemd/systemd-networkd

== status direwolf service ==
enabled
● direwolf.service - Direwolf Daemon
   Loaded: loaded (/etc/systemd/system/direwolf.service; enabled)
   Active: active (running) since Mon 2017-05-01 15:48:46 PDT; 1min 44s ago
  Process: 417 ExecStartPre=/bin/rm -f /tmp/kisstnc (code=exited, status=0/SUCCESS)
 Main PID: 523 (direwolf)
   CGroup: /system.slice/direwolf.service
           |_523 /usr/bin/direwolf -t 0 -c /etc/direwolf.conf -p

== status ax25 service ==
disabled
● ax25dev.service - AX.25 device
   Loaded: loaded (/etc/systemd/system/ax25dev.service; disabled)
   Active: active (exited) since Mon 2017-05-01 15:48:47 PDT; 1min 43s ago
  Process: 709 ExecStartPost=/bin/bash -c /usr/local/sbin/kissparms -p udr0 -f no -l 100 -r 32 -s 200 -t 500 (code=exited, status=0/SUCCESS)
  Process: 690 ExecStart=/bin/bash -c /etc/ax25/ax25-upd (code=exited, status=0/SUCCESS)
 Main PID: 690 (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/ax25dev.service
           |_696 /usr/local/sbin/mkiss /tmp/kisstnc /dev/ptmx none
           |_699 /usr/local/sbin/kissattach /dev/pts/2 udr0 44.24.197.66

== status ax25 path ==
enabled
● ax25dev.path
   Loaded: loaded (/etc/systemd/system/ax25dev.path; enabled)
   Active: active (running) since Mon 2017-05-01 15:48:46 PDT; 1min 45s ago

== status ax25-mheardd ==
enabled
● ax25-mheardd.service - AX.25 mheard daemon
   Loaded: loaded (/etc/systemd/system/ax25-mheardd.service; enabled)
   Active: active (running) since Mon 2017-05-01 15:48:47 PDT; 1min 43s ago
 Main PID: 716 (mheardd)
   CGroup: /system.slice/ax25-mheardd.service
           |_716 /usr/local/sbin/mheardd -f -n 30

== status ax25d ==
enabled
● ax25d.service - General purpose AX.25 daemon
   Loaded: loaded (/etc/systemd/system/ax25d.service; enabled)
   Active: active (running) since Mon 2017-05-01 15:48:47 PDT; 1min 43s ago
 Main PID: 715 (ax25d)
   CGroup: /system.slice/ax25d.service
           |_715 /usr/local/sbin/ax25d -l

== netstat ax25 ==
Active AX.25 sockets
Dest       Source     Device  State        Vr/Vs    Send-Q  Recv-Q
*          N7NIX-3    ax0     LISTENING    000/000  0       0
```
