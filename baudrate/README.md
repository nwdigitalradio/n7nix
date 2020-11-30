## Programmatically change baud rate 1200/9600 baud

### Introduction

The following describes a feature that remotely changes a gateway from
1200 baud to 9600 baud that was requested by J P Watters KC9KKO.

A set of scripts is used to configure a local station and remote
gateway (Winlink, APRS) to use a specific baud rate (either 1200 or
9600).

Since direwolf can decode DTMF, use DTMF tones sent from a workstation
as the mechanism to change packet baud rate on the remote gateway.

### Installation
* [Installation Notes can be found here.](#touch-tone-baudrate-installation-notes)


###### Local side

A script, _send-ttcmd.sh_, is run on a local station that specifies a
local call sign & requested baud rate for a remote gateway. If no call
sign is given on the command line then the script attempts to pull it
from the AX.25 configuration file. The baud rate request is encoded as
a Touch Tone APRS object.

```
cd
cd n7nix/baudrate
./send_ttcmd.sh -b 9600
```

###### Remote side

On the remote station Direwolf decodes the DTMF request and calls the
dw-ttcmd.sh script. This script reconfigures direwolf, kissattach &
some AX.25 parameters for the requested baud rate. Direwolf & AX.25
are restarted to read the new configuration. The requested 9600 baud
rate configuration lasts 5 minutes then resets itself back to 1200
baud. If more time is needed, run the _send_ttcmd.sh_ script on the
local workstation before the first timer has lapsed. The remote
station will delete the current timer and start a new 5 minute timer.


##### Additional features not yet implemented

* Create a white list of call signs allowed
  * Currently anyone with DTMF capability can change the baud rate on a DTMF configured gateway.
* Add frequency to the APRS object for frequency agile radios.
  * ie. On a dual band radio that supports rig control, could configure the gateway to switch from 2M to 440.
* Add a gateway identifier to select gateway to change baud rate.
  * To keep the number of Touch Tones sent to a minimum no destination gateway identifier is sent.

### Requirements
* A 'good' digital ready radio that has discriminator receive output.
* A sound modem configured for direwolf running on Linux
* AX.25 port config file located in [/etc/ax25/port.conf](#example-etcax25portconf-file)

### Script descriptions

The following 3 scripts are used to change the direwolf baud rate of a
remote machine.

* The script _speed_switch.sh_ runs on both the local & remote
machines to set the requested baud rate (either 1200 or 9600). It can
also be run manually from the command line to configure direwolf for a
specific baud rate.

###### Local machine

Use the _send-ttcmd.sh_ script to send a DTMF sequence that contains your
call sign and the requested baud rate.

###### Remote machine

When direwolf is configured properly, on receipt of the APRS Touch Tone
object it will call an external program, the _dw-ttcmd.sh_ script, to
set the requested baud rate.

#### Scripts

##### speed_switch.sh

* Runs on both local (called from _send-ttcmd.sh_) & remote (called from _dw-ttcmd.sh_) stations
* Set parameters for direwolf, kissattach & ax25parms for either 1200 or 9600 baud rates
  * Depends on file: /usr/local/etc/ax25/port.conf
  * Can be run manually to set baud rate from command line

```
Usage: speed_switch.sh [-b <speed>][-s][-d][-h]
 Default to toggling baud rate when no command line arguments found.
   -b <baudrate>  Set baud rate speed, 1200 or 9600
   -s             Display current status of devices & ports
   -d             Set flag for verbose output
   -h             Display this message
```

##### dw-ttcmd.sh

* Script called from _direwolf_ when a proper DTMF sequence is
detected on the remote station
  * This script will call _speed_switch.sh_ to set the baud rate on the remote machine.

```
Usage: dw-ttcmd.sh [-d][-h]
   -d           set debug flag
   -h           no arg, display this message
```
##### send-ttcmd.sh
* Script run from local station that sends the DTMF tones to initiate baud rate change on remote station
  * This script will call _speed_switch.sh_ to set the baud rate on the local machine.

```
Usage: send-ttcmd.sh [-c <connector>][-b <baudrate>][-f <freq>][-C <callsign>[-h]
   -b <baudrate>           either 1200 or 9600 baud, default 1200
   -c <connector_location> DRAWS left (mDin6) or right (hd15/mDin6), default: left
   -C <call sign>          Specify a call sign
   -f <frequency>          Frequency in kilohertz, exactly 6 digits.
   -t <tone_gen>           Dev only: Tone generation method, either individ, file, default: file
   -d                      set debug flag
   -h                      no arg, display this message
```

### Using Direwolf DTMF to switch baud rate on a remote machine

* Direwolf DTMF is meant to parse an APRS Object Report packet and optionally call an external program
  * Wanted to find the minimum required DTMF sequence that would generate a Report Packet so that an external program is called from Direwolf

##### Smallest DTMF string to pass direwolf filter

* This is the smallest ttOBJ I came up with ```BA236296 * A6B76B4C9B41```
  * BA **${ttgridsquare}** * A **${ttcallsign}${overlay}${checksum}** #
  * The trailing 2 digits of the Grid Square are used to pass the requested baud rate (12 or 96)

* To determine the required Touch Tone sequence for the Grid Square
  * Output of the command: ```text2tt CN96```
    * Used: Push buttons for Maidenhead Grid Square Locator
```
Push buttons for multi-press method:
"22266999996666"    checksum for call = 7
Push buttons for two-key method:
"2C6B96"    checksum for call = 6
Push buttons for fixed length 10 digit callsign:
"2696003589"
Push buttons for Maidenhead Grid Square Locator:
"236296"
Push buttons for satellite gridsquare:
"1096"
```

* To determine the required Touch Tone sequence for the call sign
  * Output of the command: ```text2tt N7NIX```
    * Used: Push buttons for two-key method
```
Push buttons for multi-press method:
"66777776644499"    checksum for call = 9
Push buttons for two-key method:
"6B76B4C9B"    checksum for call = 7
Push buttons for fixed length 10 digit callsign:
"6764902233"
```

* Only criteria for DTMF string was to get command specified by TTCMD to run
  * The following is 4 character Maidenhead  and call sign string with trailing overlay character used to create the DTMF tones.

```
BA236296 * A6B76B4C9B41
```
#### Changes to Direwolf config file

* __Note:__ all required modifications to the direwolf config file are done by executing the _tt_install.sh_ script.
* From direwolf manual:

> The APRStt Gateway function allows a user, equipped with only a DTMF (_touch tone_) pad, to enter
> information into the global APRS network. Various configuration options determine how the touch tone
> sequences get translated to APRS "object" packets

* See [APRStt Implementation Notes](https://github.com/wb2osz/direwolf/blob/master/doc/APRStt-Implementation-Notes.pdf)

###### In Channel 0 section
```
DTMF
TTOBJ 0 APP
```
* Actually do NOT want to send out the APRS Object packet over Internet to APRS-IS server or the radio.

###### In DTMF section

```
TTMHEAD BAxxxxxx
TTCMD /home/$USER/bin/dw-ttcmd.sh
```

### How to programmatically send DTMF tones

* It is way too tedious to punch in the DTMF codes for each test run.
* Unfortunately rigctl does not support setting DTMF codes for the Kenwood TM-V71a

#### Use sox from a shell script (_send-ttcmd.sh_)

* Some reference links:
  * [Audio Notes using play](http://www.noah.org/wiki/audio_notes)
  * [DTMF: mix some tones to dial a phone](http://www.noah.org/wiki/audio_notes#DTMF:_mix_some_tones_to_dial_a_phone)
  * [GENERATING DTMF WITH SOX](https://cloudacm.com/?p=3147)

* Used _sox_ command to synthesize frequency of each character.
```
sox -n $output_name synth 0.1 sin ${dmtffreq[$tonechar 1]} sin ${dmtffreq[$tonechar 2]} remix 1,2
```
* Then combined all the tonechar wav files with a little bit of silence between them.
```
sox $ttcmd_output_file tmp_ttcmd_$i.wav silence.wav ttcmd_tmp.wav
```

* I found a [number of programs which could generate DTMF wav files](DEV_NOTES.md) but
did not generate a file that worked for the codec used with DRAWS

### Touch Tone Baudrate Installation Notes

```
cd
cd n7nix
git pull
cd baudrate
./tt_install.sh
```
* Check the configured baudrate for each audio channel
```
speed_switch.sh -s
```
* Must configure radio to use receive discriminator out.
  * On Kenwood TM-V71a this means selecting DAT.SPD (518) 9600
* Must edit /etc/ax25/port.conf file to select 'receive_out=disc' before running _setalsa-tmv71a.sh_
  * Must run _setalsa-tmv71a.sh_ after editing port.conf

#### Example /etc/ax25/port.conf file
```
# Configuration for each sound card port
# version: 1.1
#
# speed is the modulator baud rate and can be:
#     1200
#     9600
#     off (for split channel)
#
# receive_out (from radio) can be:
#     disc (for discriminator) or
#     audio (for preemphasis/deemphasis)
#
# You can run 1200 baud with receive signal from discriminator
# You can NOT run 9600 baud with receive signal from audio

[port0]
speed=1200
ip_address="192.168.255.2"
receive_out=disc

[port1]
speed=1200
ip_address="192.168.255.3"
receive_out=audio

[baud_1200]
persist=32
slottime=200
txdelay=500
txtail=100
t1_timeout=3000
t2_timeout=1000

[baud_9600]
persist=32
slottime=10
txdelay=150
txtail=50
t1_timeout=2000
t2_timeout=100
```

##### Runtime Notes

* At least initially run with 3 consoles open
```
# Console 1
sudo listen -a

# Console 2
tail -f /var/log/direwolf/direwolf.log

# Console 3
time wl2kax25 n7nix
```
* Additional debug information can be found in file: _/var/log/direwolf/dw-log.txt_

* After sending command:
```
cd
cd n7nix/baudrate
./send-ttcmd.sh -b 9600
```
* wait for a response of Morse Code 'R' (dit-dah-dit)
  * If you hear something other than an 'R' or nothing then retry command

### Bugs

* After both AX.25 stacks have been restarted the final **FQ** does not show up.
  * No need to let it timeout just CTRL-C and try it again.
```
 $ time wl2kax25 kf7fit
Connected to AX.25 stack
Child process
wl2kax25: ---

wl2kax25: <[UnixLINK-0.10-B2FIHM$]
wl2kax25: sid [UnixLINK-0.10-B2FIHM$] inboundsidcodes -B2FIHM$
wl2kax25: <(am|em:h1,g:CN88nl)
wl2kax25: <Welcome
wl2kax25: <No Traffic
wl2kax25: <N7NIX de KF7FIT>
wl2kax25: >;  KF7FIT DE N7NIX (CN88nl)
wl2kax25: >[UnixLINK-0.10-B2FIHM$]
wl2kax25: >FF
# Waiting for final FQ to arrive but never happens
wl2kax25: <FQ [2]
# Ctrl-c and try again
^C
real	0m3.486s
user	0m0.014s
sys	0m0.001s
```
#### end of document
