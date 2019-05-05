## Verifying CORE Install/Config on UDRC/DRAWS

### Verify image write to micro SD card
* The fact that the micro SD card boots is a good indication that things might be OK
* If you are using a single micro SD card for your RPi and you previously ran *app_config.sh core* on the old image, the following script will verify that your current image has not been configured after writing the image to the micro SD card.
* This script is just an indication that the app_config.sh core script has successfully run or not.
  * Check with cfgcheck.sh before running app_config.sh core
```
n7nix/config/cfgcheck.sh
```
* If you see the following as the output then your image did not get copied properly.
```
-- app_config.sh core script has ALREADY been run
```
* This is the output from *cfgcheck.sh* you would expect on a new image that has not been configured **yet** with *app_config.sh core*
```
-- app_config.sh core script has NOT been run: hostname: 1, passwd: 1, logfile: 1
```

### Testing _direwolf_ & the UDRC/DRAWS Hat

* Before verifying CORE functionality you must have run the [app config script](https://github.com/nwdigitalradio/n7nix/blob/master/docs/DRAWS_CONFIG.md)
* The first few commands assume a direwolf/ax.25 installation
* The _showudrc.sh_ script in the local bin directory executes many of the commands listed below.
  * The copious output of this script will usually show you any installation & configuration anomalies

* The image you are running will **NOT** have _direwolf_ running from boot.
  * You can verify that _direwolf_ is not running by typing:
```
pidof direwolf
```
  * If this command returns with a number, it will be the process id of _direwolf_.
    * if no number is returned _direwolf_ is not running.

* To start _direwolf_
```
cd bin
sudo su
./ax25-start
```

#### Test Receive

* Connect a cable from your UDRC/DRAWWS hat to your radio.
* Tune your radio to the 2M 1200 baud APRS frequency 144.390 or some frequency known to have packet traffic
  * You should now be able to see the packets decoded by _direwolf_

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
# Test left channel
./btest.sh -P udr0
# Test right channel
./btest.sh -P udr1
# To see all the options available
./btest.sh -h
```

* This will send either a position beacon or a message beacon
with the -p or -m options.

* Using a browser go to: [aprs.fi](https://aprs.fi/)
  * Under Other Views, click on raw packets
  * Put your call sign followed by an asterisk in "Originating callsign"
  * Click search, you should see the beacon you just transmitted.

#### Check status of all AX.25 & _direwolf_ processes started with systemd

* Open another console window to the pi and as user pi type:
```bash
ax25-status -d
```
* After _== failed & loaded but inactive units==_ you should see
```
0 loaded units listed.
```

* In your local bin directory(_~/bin_) you can stop and start the entire ax.25/tnc
stack including _direwolf_ with these commands:
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

#### check ALSA soundcard enumeration & levels

```bash
cd ~/bin
./sndcard.sh
```

#### check ALSA settings for deviation

* Show the left & right audio channel settings

```bash
alsa-show.sh

 ===== ALSA Controls for Radio Tansmit =====
LO Driver Gain  L:[0.00dB]	R:[0.00dB]
PCM	        L:[0.00dB]	R:[0.00dB]
DAC Playback PT	L:[PTM_P3]	R:[PTM_P3]
LO Playback CM	[Full Chip CM]

 ===== ALSA Controls for Radio Receive =====
ADC Level	L:[0.00dB]	R:[0.00dB]
IN1		L:[Off]		R:[Off]
IN2		L:[10 kOhm]	R:[10 kOhm
```
###### Set output ie. deviation with these controls
* Each of these outputs has its own amplifier
* PCM : digital control
  * output samples are multiplied by a value determined by this control before being sent to the DAC
* LO Driver Gain : Analog control
  * determines the gain of the *ANALOG* output amplifier.

###### Set input with this control
* ADC Level : digital control

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
* Battery: CR 1220 3V lithium non-rechargeable
* Check status of chronyd daemon
```
systemctl status chronyd
```

* Check how many gps channels (satellites) are active
```
gpsmon
```
* or
```
cgps
```
* or
```
# For Raw NMEA sentences
gpspipe -r

# For GPS binary sentences
gpspipe -R

# For gpsd native data
gpspipe -w
```

#### Check chrony synchronization
* **NOTE:** with just GPS and no Internet time servers it often takes 10 minutes for the chrony server to enter online mode.
* To check if chrony is synchronized, make use of the _tracking_, _sources_, and _sourcestats_ commands.

* Display information about the current time sources that chronyd is accessing.
```
chronyc sources
```
```
210 Number of sources = 6
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
#x GPS                           0   3   377    12    +83ms[  +83ms] +/-  102ms
#* PPS                           0   3   377    11   +239ms[ +239ms] +/-  242ns
^- 45.32.199.189.vultr.com       2   6   377   293   +237ms[ +237ms] +/-   69ms
^- t2.time.gq1.yahoo.com         2   8   377    43   +239ms[ +239ms] +/-   34ms
^- linode1.ernest-doss.org       3   7   377    43   +242ms[ +242ms] +/-  124ms
^- t1.time.bf1.yahoo.com         2   6   377    35   +240ms[ +240ms] +/-   47ms
```
* Check source stats
```
chronyc sourcestats
```
```
210 Number of sources = 6
Name/IP Address            NP  NR  Span  Frequency  Freq Skew  Offset  Std Dev
==============================================================================
GPS                         8   6    55   -569.805   1137.333   -199ms  9188us
PPS                         7   5    48     -0.328      0.026  +1761us   134ns
clockb.ntpjs.org           28  13  107m     -0.347      0.030   -177us    55us
h184-60-28-49.mdtnwi.dsl>  35  19  139m     -0.059      0.082  +2990us   285us
clock.trit.net             29  13  141m     -0.256      0.013  -8385us    35us
mia1.m-d.net               18   9   73m     -0.280      0.190   -588us   235us
```

* Check chrony tracking - Check to confirm that NEMA is being used as the reference.
  * shows how good current time is and what the offset of the system clock is.
* Link for [field definitons](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/sect-using_chrony)
```
chonyc tracking
```
```
Reference ID    : 50505300 (PPS)
Stratum         : 1
Ref time (UTC)  : Sat Dec 15 18:10:07 2018
System time     : 0.000000008 seconds fast of NTP time
Last offset     : -0.000406383 seconds
RMS offset      : 0.000406383 seconds
Frequency       : 1.149 ppm fast
Residual freq   : +0.259 ppm
Skew            : 0.123 ppm
Root delay      : 0.000000 seconds
Root dispersion : 0.002010 seconds
Update interval : 0.0 seconds
Leap status     : Normal
```

### Testing AX.25

* Verify AX.25 & _direwolf_ are running by running this command:
```
ax25-status
```
* expect this output

```
Status for direwolf.service: RUNNING and ENABLED
Status for ax25dev.service: RUNNING and ENABLED
Status for ax25dev.path: RUNNING and ENABLED
Status for ax25-mheardd.service: RUNNING and ENABLED
Status for ax25d.service: RUNNING and ENABLED
```
* If you don't see the above then start AX.25 & _direwolf_ like this:
```
cd bin
sudo su
./ax25-start
```

* In a console type:
```bash
netstat --ax25
```
* You should see a list of open listening sockets that looks something like this:
```
Active AX.25 sockets
Dest       Source     Device  State        Vr/Vs    Send-Q  Recv-Q
*          N7NIX-0    ax1     LISTENING    000/000  0       0
*          N7NIX-10   ax1     LISTENING    000/000  0       0
```

* Display AX.25 calls recently heard.
  * Must have connection to radio

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

### Test RPi sound
* Be sure the volume is turned up for this audio device.
* enable RPi audio device in _/boot/config.txt_ by uncommenting the following line
```
dtparam=audio=on
```

#### Test analog audio
* Play a short xastir wave file
```
cd /usr/share/xastir/sounds
aplay -D "plughw:0,0" bandopen.wav
```
* Output pink noise
```
speaker-test --channels 2 --rate 48000 --device plughw:0,0
```

#### Test HDMI audio
* Add the following to _/boot/config.txt_ , then reboot
```
# forces HDMI mode
hdmi_drive=2
```

* Test using a xastir wave file

```
cd /usr/share/xastir/sounds
aplay -D "plughw:0,1" silence.wav bandopen.wav

```
* Output pink noise
```
speaker-test --channels 2 --rate 48000 --device plughw:0,1
```
