## Notes for DRAWS image

* You should notice the first time the DRAWS image is booted it auto boots a second time.
  * This is to expand the compressed file system.

* The initial file system image is found at http://archive.compasslinux.org/images/
  * image_2018-11-18-compass.zip
* The DRAWS RPi image which starts with the Compass image is currently residing here:
  * http://nwdig.net/downloads/

* The programs in the following table are added to the compass image.

### Table of Installed Programs

* PKG = Debian package for RPi (armhf) available
* DW = requires Direwolf
* AX25 = requires AX.25 stack


|    Program   |  Version |  PKG  |  DW   |  AX25 |
| :---------:  | :------: | :---: | :---: | :---: |
| direwolf     |   dev 1.6 B  |       |       |       |
| libax25      |   1.1.0  |  yes  | yes   |  yes  |
| ax25apps     |   1.0.5  |  yes  | yes   |  yes  |
| ax25tools    |   1.0.3  |  yes  | yes   |  yes  |
| rmsgw        |   2.5.0  |       |  yes  |  yes  |
| paclink-unix |    0.7   |       |  yes  |  yes  |
| mutt         |   1.7.2  |  yes  |  yes  |  yes    |
| claws-mail   |   3.14.1 |  yes  |       |       |
| rainloop     |   1.12.1 |  yes  |       |       |
| FBB BBS      | 7.0.8-beta7 |    |  yes  |  yes  |
| Xastir       |   2.1.1     |    |  yes  |       |
| YAAC           | 1.0-beta129  |      | yes  |
| dstarrepeater  | 1.20180703-4 | yes |   |   |
| dstarrepeaterd | 1.20180703-4 | yes |   |   |
| ircddbgateway  | 1.20180703-1 | yes |   |   |
| ircccbgatewayd | 1.20180703-1 | yes |   |   |
| ARDOP        |  2      |      |     |   |
| ARIM         |  2.6    |      |     |   |
| js8call      |  1.0.1  | yes  |     |   |
| wsjt-x       |  2.0.1  | yes  |     |   |
| hamlib       |  3.3    |      |     |   |
| flxmlrpc lib |  0.1.4  |      |     |   |
| fldigi       |  4.1.03 |      |     |   |
| flrig        |  1.3.43 |      |     |   |
| flmsg        |  4.0.8  |      |     |   |
| flamp        |  2.2.04 |      |     |   |
| iptables     |  1.6.0  |  yes |     |   |
| lm-sensors   |  3.4.0  |  yes |     |   |
