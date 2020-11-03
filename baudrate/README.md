## Programatically change baud rate 1200/9600 baud

# PRELIMINARY

Use the following 3 scripts to change the direwolf baud rate of a remote
machine.  _speed_switch.sh_ runs on both the local & remote machines
to set the requested baud rate (either 1200 or 9600)


* On the local machine:

Use the _send-ttcmd.sh_ script to send a DTMF sequence that contains your
call sign and the requested baud rate.

* On the remote machine:

When direwolf is configured properly it will call an external program.
Use the _dw-ttcmd.sh_ script, called by direwolf, to set the requested
baud rate.


### Scripts

#### speed_switch.sh
* Set parameters for kissattach & ax25parms for either 1200 or 9600 baud rates
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

#### dw-ttcmd.sh

* Script called from _direwolf_ when a proper DTMF sequence is
detected on the remote station
  * This script will call _speed_switch.sh_

```
Usage: dw-ttcmd.sh [-d][-h]
   -d           set debug flag
   -h           no arg, display this message
```
#### send-ttcmd.sh
* Script run from local station that sends the DTMF tones to initiate baud rate change on remote station
  * This script will call _speed_switch.sh_

```
Usage: send-ttcmd.sh [-c <connector>][-b <baudrate>][-h]
   -b <baudrate>           either 1200 or 9600 baud, default 1200
   -c <connector_location> either left (mDin6) or right (hd15/mDin6), default: left
   -d                      set debug flag
   -h                      no arg, display this message
```

### Using DTMF to switch a remote machine
#### Changes to direwolf config
* Direwolf DTMF is meant to generate an APRS Object Report packet
  * Find the minimum required config to generate a Report packet so that an external program is called.

##### Smallest DTMF string to pass direwolf filter

* How I came up with ```BA236288 * A6B76B4C9B7```
  * Grid square plus call sign

* text2tt CN88
```
Push buttons for multi-press method:
"222668888A8888"    checksum for call = 2
Push buttons for two-key method:
"2C6B88"    checksum for call = 7
Push buttons for fixed length 10 digit callsign:
"2688003589"
Push buttons for Maidenhead Grid Square Locator:
"236288"
Push buttons for satellite gridsquare:
"1088"
```
* text2tt N7NIX
```
pi@testit2:/usr/local/src/direwolf-dev/build $ text2tt N7NIX
Push buttons for multi-press method:
"66777776644499"    checksum for call = 9
Push buttons for two-key method:
"6B76B4C9B"    checksum for call = 7
Push buttons for fixed length 10 digit callsign:
"6764902233"
```

* Only criteria for DTMF string was to execute TTCMD
  * 4 character Maidenhead  and call sign string

```
BA236288 * A6B76B4C9B7
```
#### Changes to Direwolf config file
* From direwolf manual

The APRStt Gateway function allows a user, equipped with only a DTMF (_touch tone_) pad, to enter
information into the global APRS network. Various configuration options determine how the touch tone
sequences get translated to APRS "object" packets

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
TTCMD /root/dw-ttcmd.sh
```

### How to programatically send DTMF tones

* It is way too tedious to punch in the DTMF codes for each test run.
* Unfortunately rigctl does not support setting DTMF codes for the Kenwood TM-V71a

#### Use sox (play) from a shell script

* [Audio Notes using play](http://www.noah.org/wiki/audio_notes)
* http://www.noah.org/wiki/audio_notes#DTMF:_mix_some_tones_to_dial_a_phone
* https://cloudacm.com/?p=3147

* Used sox _play_ command to synthesize frequency of each character.
```
play -q -n synth 0.1 sin ${dmtffreq[$tonechar 1]} sin ${dmtffreq[$tonechar 2]} remix 1,2 2> /dev/null
```
* Unfortunately calling play for each tone pair is much slower than playing a generated wav file.

* The programs I tried which did generate DTMF wav files did not
generate a file that worked for the codec used with DRAWS

#### end of document
