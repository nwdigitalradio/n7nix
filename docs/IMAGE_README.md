## Notes for DRAWS image

* You should notice the first time the DRAWS image is booted it auto boots a second time.
  * This is to expand the compressed file system.

* The initial file system image is found at https://www.raspberrypi.org/downloads/raspbian/
  * Raspbian Buster with desktop
* The DRAWS RPi image which uses the Raspbian with desktop image is currently residing here:
  * http://nwdig.net/downloads/

* The programs in the following table are added to the Raspbian image.

### Table of Installed Programs

* PKG = Debian package for RPi (armhf) available
* DW = requires Direwolf
* AX25 = requires AX.25 stack


|    Program   |  Version |  PKG  |  DW   |  AX25 |
| :---------:  | :------: | :---: | :---: | :---: |
| direwolf     |   dev 1.6 D  |       |       |       |
| libax25      |   1.1.3  |  yes  |  yes  |  yes  |
| ax25apps     |   2.0.1  |  yes  |  yes  |  yes  |
| ax25tools    |   1.0.5  |  yes  |  yes  |  yes  |
| rmsgw        |   2.5.1  |       |  yes  |  yes  |
| paclink-unix |    0.10  |       |  yes  |  yes  |
| mutt         |   1.10.1  |  yes  |  yes  |  yes    |
| claws-mail   |   3.14.1  |  yes  |       |       |
| rainloop     |   1.12.1  |  yes  |       |       |
| FBB BBS      |   7.0.9   |       |  yes  |  yes  |
| Xastir       |   2.1.5     |    |  yes  |       |
| YAAC           | 1.0-beta145  |      | yes  |
| dstarrepeater  | 1.20180703-4 | yes |   |   |
| dstarrepeaterd | 1.20180703-4 | yes |   |   |
| ircddbgateway  | 1.20180703-1 | yes |   |   |
| ircccbgatewayd | 1.20180703-1 | yes |   |   |
| ARDOP        |  2      |      |     |   |
| ARIM         |  2.6    |      |     |   |
| js8call      |  2.1.1  |  yes  |     |   |
| wsjt-x       |  2.1.2  |  yes  |     |   |
| hamlib       |  3.3    |      |     |   |
| flxmlrpc lib |  0.1.4  |      |     |   |
| fldigi       |  4.1.09 |      |     |   |
| flrig        |  1.3.49 |      |     |   |
| flmsg        |  4.0.14 |      |     |   |
| flamp        |  2.2.05 |      |     |   |
| fllog        |  1.2.6  |      |     |   |
| iptables     |  1.8.2  |  yes |     |   |
| lm-sensors   |  3.5.0  |  yes  |     |   |
