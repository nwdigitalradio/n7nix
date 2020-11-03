## Programmatically change baud rate 1200/9600 baud

### Introduction

The following feature was requested by J P Watters KC9KKO.

If we had support for simultaneous 1200 & 9600 baud packet with a
single radio on a channel that would be idea. With the current way
that Direwolf works it is not clear how that is possible.

Until there is successful detection of both 1200 & 9600 baud packets
on a single channel the method descibed below is a way to configure a
remote gateway (Winlink, APRS) to handle a requested baud rate.

Since direwolf can decode DTMF, use DTMF tones as the mechanism to
change packet baud rate on the remote gateway.

A script (send_ttcmd.sh) is run on a local station that specifies call
sign & requested baud rate for a remote gateway.  The request is
encoded as a Touch Tone APRS object. On the remote station Direwolf
decodes the DTMF request, verifies the call sign is found in a white
list and configures itself to decode the specified baud rate.

### Script descriptions

The following 3 scripts are used to change the direwolf baud rate of a
remote machine.

* The script _speed_switch.sh_ runs on both the local & remote
machines to set the requested baud rate (either 1200 or 9600). It can
also be run manually from the command line to configure direwolf for a
specific baud rate.

* On the local machine:

Use the _send-ttcmd.sh_ script to send a DTMF sequence that contains your
call sign and the requested baud rate.

* On the remote machine:

When direwolf is configured properly on receipt of the APRS Touch Tone
object it will call an external program, the _dw-ttcmd.sh_ script, to
set the requested baud rate.

[Installation Notes](#installation-notes)

#### Scripts

##### speed_switch.sh
* Set parameters for direwolf, kissattach & ax25parms for either 1200 or 9600 baud rates
  * Depends on file: /usr/local/etc/ax25/port.conf
  * Runs on both local & remote stations
  * Can be run manually from the command line
    * Used by both _dw-ttcmd.sh_ and _send-ttcmd.sh_

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
Usage: send-ttcmd.sh [-c <connector>][-b <baudrate>][-h]
   -b <baudrate>           either 1200 or 9600 baud, default 1200
   -c <connector_location> either left (mDin6) or right (hd15/mDin6), default: left
   -d                      set debug flag
   -h                      no arg, display this message
```

### Using Direwolf DTMF to switch baud rate on a remote machine

* Direwolf DTMF is meant to generate an APRS Object Report packet
  * Find the minimum required config to generate a Report packet so that an external program is called.

##### Smallest DTMF string to pass direwolf filter

* This is the smallest ttOBJ I came up with ```BA236212 * A6B76B4C9B7```
  * Grid square plus call sign
  * The trailing 2 digits of the Grid Square are used to pass the requested baud rate (12 or 96)

* To determine the required Touch Tone sequence for the Grid Square
  * Output of the command: ```text2tt CN12```
```
Push buttons for multi-press method:
"2226612222"    checksum for call = 7
Push buttons for two-key method:
"2C6B12"    checksum for call = 4
Push buttons for fixed length 10 digit callsign:
"2612003589"
Push buttons for Maidenhead Grid Square Locator:
"236212"
Push buttons for satellite gridsquare:
"1012
```
* To determine the required Touch Tone sequence for the call sign
  * Output of the command: ```text2tt N7NIX```
```
Push buttons for multi-press method:
"66777776644499"    checksum for call = 9
Push buttons for two-key method:
"6B76B4C9B"    checksum for call = 7
Push buttons for fixed length 10 digit callsign:
"6764902233"
```

* Only criteria for DTMF string was to get command specified by TTCMD to run
  * The following is 4 character Maidenhead  and call sign string used to create the DTMF tones.

```
BA236212 * A6B76B4C9B7
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
TTOBJ 0 1 WIDE1-1
```
* Actually do NOT want to send out an APRS packet so have to play with the TTOBJ line.

###### In DTMF section

```
TTMHEAD BAxxxxxx
TTCMD /home/$USER/bin/dw-ttcmd.sh
```

### How to programmatically send DTMF tones

* It is way too tedious to punch in the DTMF codes for each test run.
* Unfortunately rigctl does not support setting DTMF codes for the Kenwood TM-V71a

#### Use sox (play) from a shell script (send-ttcmd.sh)

* [Audio Notes using play](http://www.noah.org/wiki/audio_notes)
* http://www.noah.org/wiki/audio_notes#DTMF:_mix_some_tones_to_dial_a_phone
* https://cloudacm.com/?p=3147

* Used sox _play_ command to synthesize frequency of each character.
```
play -q -n synth 0.1 sin ${dmtffreq[$tonechar 1]} sin ${dmtffreq[$tonechar 2]} remix 1,2 2> /dev/null
```
* Unfortunately calling play for each tone pair is much slower than playing a generated wav file.
  * Needs more research

* The programs I tried which did generate DTMF wav files did not
generate a file that worked for the codec used with DRAWS

### Installation Notes

```
cd
cd n7nix
git pull
cd baudrate
./tt_install.sh

speed_switch.sh -s
```
#### end of document
