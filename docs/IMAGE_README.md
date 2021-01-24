## Notes for DRAWS image

* You should notice the first time the DRAWS image is booted it auto boots a second time.
  * This is to expand the compressed file system.

* The initial __Raspberry Pi OS__ file system image is found [here](https://www.raspberrypi.org/software/operating-systems/#raspberry-pi-os-32-bit)
  * Raspberry Pi OS with desktop
* The DRAWS RPi image which uses the __Raspberry Pi OS__ with desktop image is currently residing here:
  * http://nwdig.net/downloads/

* The programs in the following table are added to the __Raspberry Pi OS__ image.

### Table of Installed Programs

* PKG = Debian package for RPi (armhf) available
* DW = requires Direwolf
* AX25 = requires AX.25 stack

###              Packet

|    Program   |  Version |  PKG  |  DW   |  AX25 |
| :---------:  | :------: | :---: | :---: | :---: |
| direwolf     |   DEV 1.7 A  |       |       |       |
| libax25      |   1.1.3  |  yes  |  yes  |  yes  |
| ax25apps     |   2.0.1  |  yes  |  yes  |  yes  |
| ax25tools    |   1.0.5  |  yes  |  yes  |  yes  |
| aprx         |   2.9.0  |       |  yes  |  yes  |
| rmsgw        |   2.5.1  |       |  yes  |  yes  |
| paclink-unix |   0.10   |       |  yes  |  yes  |
| mutt         |   1.10.1  |  yes  |  yes  |  yes    |
| claws-mail   |   3.17.3  |  yes  |       |       |
| rainloop     |   1.15.0  |  yes  |       |       |
| FBB BBS      |   7.03  |       |  yes  |  yes  |
| Xastir       |   2.1.7   |       |  yes  |       |
| YAAC *       | 1.0-beta163  |      | yes  |
| iptables     |  1.8.2  |  yes |     |   |
| sensors      |  3.5.0  |  yes  |     |   |
| chattervox   |  2.13.1 |       |  yes  |  yes  |


###           D-Star

|    Program   |  Version |  PKG  |  DW   |  AX25 |
| :---------:  | :------: | :---: | :---: | :---: |
| dstarrepeater  | 1.20180703-4 | yes |   |   |
| dstarrepeaterd | 1.20180703-4 | yes |   |   |
| ircddbgateway  | 1.20180703-1 | yes |   |   |
| ircccbgatewayd | 1.20180703-1 | yes |   |   |


###              HF

|    Program   |  Version |  PKG  |  DW   |  AX25 |
| :---------:  | :------: | :---: | :---: | :---: |
| ARDOP        |  2      |      |     |   |
| ARIM         |  2.6    |      |     |   |
| js8call      |  2.2.0  |  yes  |     |   |
| wsjt-x       |  2.2.2  |  yes  |     |   |
| hamlib       |  3.3    |      |     |   |
| flxmlrpc lib |  0.1.4  |      |     |   |
| fldigi       |  4.1.17 |      |     |   |
| flrig        |  1.3.53 |      |     |   |
| flmsg        |  4.0.17 |      |     |   |
| flamp        |  2.2.05 |      |     |   |
| fllog        |  1.2.6  |      |     |   |
