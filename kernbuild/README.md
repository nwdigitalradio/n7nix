## Notes on building a custom kernel for RPi and copying to proper directory

##### Brief description of repo contents

* build.sh - build a Linux kernel starting from default config
* flashit.sh - copies an RPi Compass root file system to a flash part
* kern_cpy_flash.sh - copy kernel components to a flash part
* kern_cpy_local.sh - copy kernel components to a local directory
(_tmp_ or _repo_)
* kern_cpy_remote.sh - copy kernel components to a remote machine
* kern_upd_udrc.sh - Used to find the differences between a compass
reference kernel source tree and a Raspbian kernel.
* _kern_ directory contains kernel components suitable for coping to
flash part
  * Built with _kern_cpy_local.sh_
  * Used by _kern_cpy_flash.sh_ & _kern_cpy_remote.sh_

#### build.sh
* must be run from base of kernel tree
```
.\build.sh
```
* Displays tools version & git branch being built
* uses udr_defconfig file
* modules are copied to ../lib/modules
* builds all files required to boot an RPi
* Assumes cross compile build tools are already installed.
  * Used this [Kernel Building link](https://www.raspberrypi.org/documentation/linux/kernel/building.md) as reference.

After building a kernel you need to copy the kernel image, device
tree & overlay files to the boot partition and the modules to the root
file system partition. That is facilitated by the kern_cpy_*.sh
scripts described below.

#### flashit.sh

* Automatically downloads & uncompresses the latest full image from wilderness (untested).
* Copies downloaded compass image to a flash part
* File names with "compass-lite" have no support for window manager
* Untested current file system images can be found
[here](http://archive.compasslinux.org/images/wilderness/)
* Defaults to downloading & copying a full image that supports a window manager created on todays date.
* Requires:
  * modify script **flash device name** _flash_dev_ or you could hose your workstation
  * variable _img_date_ defaults to todays date unless specified
  * variable _kernlite_ defaults to _false_
    * Set _kernlite="true"_ to get image without a window manager ie. headless
  * run script as root in directory containing compass image

#### kern_cpy_flash.sh

* Copies kernel components to a flash card.
* Requires:
  *  SD card with a boot partition & root file system partitiion.
  * run kern_cpy_local.sh first to get kernel components
  * Needs to be run below directory containing kernel components
  (_kern_) created
by kern_cpy_local.sh
* Copies from the following directory structure to appropriate RPi file system

```
$BASE_DIR/lib/modules/
$BASE_DIR/boot/
$BASE_DIR/boot/dts/*.dtb
$BASE_DIR/boot/dts/overlays/*.dtb*
```
#### kern_cpy_local.sh

* Copies kernel components from a linux tree to some other location like a github repo
* Used to refresh the _kern_ directory in the repo or other directory
* Requires:
  * run from a directory to conventiently store kernel
components like _tmp_ or a _repo_ directory.
  * edit script variarbles:
    * SRC_DIR with directory location of kernel source tree
    * kernver with kernel version to use
  * kernel source directory needs to be here: $SRC_DIR/raspi_$kernver
* Define DRY_RUN variable to only display what would be copied.

#### kern_cpy_remote.sh

* Requires:
  * network connection to a remote machine
  * root login with ssh enabled on remote machine
  * run kern_cpy_local.sh first to get kernel components
  * Needs to run below directory containing kernel components (_kern_) created by kern_cpy_local.sh
* Edit script variables DSTADDR & IPADDR to remote machine IP address
$DSTADDR:$IPADDR
* Command line argument is last octet of remote IP address.
* Define DRY_RUN variable to only display what would be copied to
remote machine.
* Should backup kernel image, _/boot/kernel7.img_ before running this
script.

#### kern_upd_udrc.sh

* Contains a list of files that are needed for udrc/udrx support
* Need to edit the following in this script:
  * directory & version of target Raspbian source tree
  * directory of reference compass kernel tree.
* Can be run from any directory as user.
* Does a diff & counts line differences of required files to
facilitate modifying newer Raspbian kernel source tree.
* Command line options
```
-c Changes target source files to support udrc/udrx
-d Shows diff of all source files required by udrc/udrx
```
* Uncomment _SHOW_DIFF=1_ to see differences otherwise just counts
number of lines that are different.
* Example output
```
Update a kernel source tree for UDRC/UDRX
Reference kernel: /home/gunn/dev/github/linux
Target kernel /home/kernel/raspi_linux/raspi_4.15.rc8
=== diff udr_defconfig , 54 lines ===
=== diff bcm2835-i2s.c, 0 lines ===
=== diff Kconfig, 3 lines ===
=== diff Makefile, 0 lines ===
=== diff udrc.c, 0 lines ===
=== diff tlv320aic32x4.c, 0 lines ===
=== diff tlv320aic32x4.h, 2 lines ===
=== diff tlv320aic32x4-i2c.c, 2 lines ===
=== diff tlv320aic32x4-spi.c, 2 lines ===
=== diff udrc.h, 0 lines ===
=== diff tlv320aic32x4.h, 2 lines ===
=== diff udrc-boost-output-overlay.dts, 0 lines ===
=== diff udrc-overlay.dts, 0 lines ===
=== diff udrx-overlay.dts, 0 lines ===
=== diff Makefile, 7 lines ===

Total files checked: 15

kern_upd_udrc.sh: FINISHED
```
