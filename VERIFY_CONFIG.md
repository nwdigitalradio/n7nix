## Verifying CORE Install/Config on UDRC/DRAWS
### Testing direwolf & the UDRC

#### Test Receive

* Connect a cable from your UDRC to your radio.
* Tune your radio to the 2M 1200 baud APRS frequency 144.390 or some frequency known to have packet traffic
  * You should now be able to see the packets decoded by direwolf

* Open a console on your pi and type:
```bash
tail -f /var/log/direwolf/direwolf.log
```

* or open another console window & start up a packet spy

```bash
sudo su
listen -at
```

#### Test Transmit

* Tune your radio to the 1200 baud APRS frequency: 144.39
```bash
cd
cd n7nix/debug
sudo su
./btest.sh -P [udr0|udr1]
# To see all the options available
./btest.sh -h
```

* This will send either a position beacon or a message beacon
with the -p or -m options.

* Using a browser go to: [aprs.fi](https://aprs.fi/)
  * Under Other Views, click on raw packets
  * Put your call sign followed by an asterisk in "Originating callsign"
  * Click search, you should see the beacon you just transmitted.

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
cd ~/bin
./ax25-stop
./ax25-start
```

* Other progams that confirm that the installation was successful

#### check hardware version of Raspberry Pi & DRAWS Hat

```bash
cd ~/n7nix/bin
./piver.sh
./udrcver.sh
```

#### check ALSA soundcard enumeration

```bash
cd ~/bin
./sndcard.sh
```

#### check ALSA settings for deviation

```bash
cd ~/n7nix/debug
./alsa-show.sh
PCM	        L:[0.00dB], R:[0.00dB]
ADC Level	L:[-2.00dB], R:[0.00dB]
LO Driver Gain  L:[0.00dB], R:[11.00dB]
```

#### check A2D converter

```
sensors
```
```
ads1015-i2c-1-48
Adapter: bcm2835 I2C adapter
User ADC Differential:  +0.00 V
+12V:                  +12.27 V
User ADC 1:             +0.00 V
User ADC 2:             +0.00 V
```

#### Check GPS

```
gpsmon
```

#### Check NTP clock

```
chronyc sources
```
```
210 Number of sources = 6
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
#x GPS                           0   3   377    12    +83ms[  +83ms] +/-  102ms
#- PPS                           0   3   377    11   +239ms[ +239ms] +/-  242ns
^- 45.32.199.189.vultr.com       2   6   377   293   +237ms[ +237ms] +/-   69ms
^- t2.time.gq1.yahoo.com         2   8   377    43   +239ms[ +239ms] +/-   34ms
^- linode1.ernest-doss.org       3   7   377    43   +242ms[ +242ms] +/-  124ms
^- t1.time.bf1.yahoo.com         2   6   377    35   +240ms[ +240ms] +/-   47ms
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
