## Notes for DRAWS image

* You should notice the first time the DRAWS image is booted it auto boots a second time.
  * This is to expand the compressed file system.

* The initial file system image is found at http://archive.compasslinux.org/images/
  * image_2018-11-18-compass.zip
* The programs in the following table are added to the compass image.

### Table of installed programs

* PKG = Debian package for RPi available
* DW = requires Direwolf
* AX25 = requires AX.25 stack


|    Program   |  Version |  PKG  |  DW   |  AX25 |
| :---------:  | :------: | :---: | :---: | :---: |
| direwolf     |   dev    |       |       |       |
| libax25      |   1.1.0  |  yes  | yes   |  yes  |
| ax25apps     |   1.0.5  |  yes  | yes   |  yes  |
| ax25tools    |   1.0.3  |  yes  | yes   |  yes  |
| rmsgw        |   2.5.0  |       |  yes  |  yes  |
| paclink-unix |    0.7   |       |  yes  |  yes  |
| claws-mail   |   3.14.1 |  yes  |       |       |
| FBB BBS      | 7.0.8-beta7 |    |  yes  |  yes  |
| Xastir       |   2.0.8     | yes | yes  |       |
| YAAC           | 1.0-beta129  |      | yes  |
| dstarrepeater  | 1.20180703-4 | yes |   |   |
| dstarrepeaterd | 1.20180703-4 | yes |   |   |
| ircddbgateway  | 1.20180703-1 | yes |   |   |
| ircccbgatewayd | 1.20180703-1 | yes |   |   |
| ARDOP        |  2      |      |     |   |
| ARIM         |  2.4    |      |     |   |
| js8call      |  0.10.1 |      |     |   |
| wsjt-x       |  2.0.0  |      |     |   |
| hamlib       |  3.3    |      |     |   |
| fldigi       |  4.0.18 |      |     |   |
| flrig        |  1.3.41 |      |     |   |
| iptables     |  1.60   |  yes |     |   |
| lm-sensors   |  3.4.0  |  yes |     |   |
