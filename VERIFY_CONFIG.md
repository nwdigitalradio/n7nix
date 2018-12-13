## Verifying CORE Install/Config on UDRC/DRAWS
### Testing direwolf & the UDRC
#### Monitor Receive packets from direwolf
* Connect a cable from your UDRC to your radio.
* Tune to an active digital frequency such as 2M APRS, 144.390 MHz
* Open a console to the pi and type:
```bash
tail -f /var/log/direwolf/direwolf.log
```
* Tune your radio to the 2M 1200 baud APRS frequency 144.390 or some frequency known to have packet traffic
  * You should now be able to see the packets decoded by direwolf

#### Check status of all AX.25 & direwolf processes started with systemd
* Open another console window to the pi and as user pi type:
```bash
cd ~/bin
./ax25-status
```

* In the same directory you can stop and start the entire ax.25/tnc
stack including direwolf with these commands:
  * Note you need to do this as root

```bash
sudo su
./ax25-stop
./ax25-start
```
#### Verify version of Raspberry Pi, UDRC,

* There are some other progams in the bin directory that confirm that the installation went well.
  * While in local bin directory as user pi
```bash
cd ~/bin
./piver.sh
./udrcver.sh
```

#### check ALSA soundcard enumeration
  * While in local bin directory as user pi
```bash
cd ~/bin
./sndcard.sh
```

### Testing AX.25

* In a console type:
```bash
netstat --ax25
```
* You should see a list of open listening sockets that looks something like this:
```
Active AX.25 sockets
Dest       Source     Device  State        Vr/Vs    Send-Q  Recv-Q
*          N7NIX-10   ax0     LISTENING    000/000  0       0
*          N7NIX-2    ax0     LISTENING    000/000  0       0
```
* In another console as root type:

```bash
sudo su
listen -at
```
* Over time you should see packets scrolling up the screen

* In a console type:
```bash
mheard
```
* You should see something like this:
```
Callsign  Port Packets   Last Heard
KG7HQ-15   udr0     72   Sat Apr  1 08:52:59
N7DKL-9    udr0      8   Sat Apr  1 08:52:46
W7COA-9    udr0     23   Sat Apr  1 08:52:28
BALDI      udr0      2   Sat Apr  1 08:52:18
WA7EBH-15  udr0      2   Sat Apr  1 08:52:13
VA7RKC-9   udr0      1   Sat Apr  1 08:52:06
VE7OLG-9   udr0      2   Sat Apr  1 08:51:53
VE7ZKI-8   udr0      3   Sat Apr  1 08:51:48
VA7MAS     udr0      6   Sat Apr  1 08:51:37
SEDRO      udr0      2   Sat Apr  1 08:51:35
VE7ZNS     udr0      1   Sat Apr  1 08:51:22
W7WEC-9    udr0      7   Sat Apr  1 08:51:19
SNOVAL     udr0      1   Sat Apr  1 08:50:58
VE7FAA-9   udr0      8   Sat Apr  1 08:50:37
WB4KGY-3   udr0      1   Sat Apr  1 08:49:36
VE7NV-1    udr0      1   Sat Apr  1 08:48:52
KF7VOP     udr0      1   Sat Apr  1 08:48:35
VA7HXD     udr0      1   Sat Apr  1 08:47:53
NG7W       udr0      3   Sat Apr  1 08:47:26
VE7MKF-3   udr0      3   Sat Apr  1 08:46:48
K7KCA-12   udr0     11   Sat Apr  1 08:46:19
LDYSMH     udr0      1   Sat Apr  1 08:46:00
DOGMTN     udr0      1   Sat Apr  1 08:45:44
VE7RVT-12  udr0      1   Sat Apr  1 08:44:36
VA7MP      udr0      1   Sat Apr  1 08:43:04
```
