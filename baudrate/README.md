## Programatically change baud rate 1200/9600 baud

# PRELIMINARY

### Scripts

#### speed_switch.sh
* Set parameters for kissattach & ax25parms for either 1200 or 9600 baud rates
  * Depends on file: /usr/local/etc/ax25/port.conf

```
Usage:
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

#### Use program to generate wav file to pass to radio sound card.

* Found a python program on github that supports numbers, ABCD and '*'
  * [cleversonahum / dtmf-generator](https://github.com/cleversonahum/dtmf-generator/blob/main/dtmf-generator.py)

