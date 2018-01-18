## Notes on building a custom kernel for RPi and copying to proper directory

##### Brief description of repo contents
* build.sh - build a Linux kernel starting from default config
* flashit.sh - copies an RPi root file system to a flash part
* kern_cpy_flash.sh - copy kernel components to a flash part
* kern_cpy_local.sh - copy kernel components to a local directory (repo)
* kern_cpy_remote.sh - copy kernel components to a remote machine
* kern directory contains kernel components

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

After building a kernel you need to copy the kernel image & device
tree & overlay files to the boot partition and the modules to the root
file system partition. That is facilitated by the kern_cpy_*.sh
scripts described below.

#### kern_cpy_flash.sh

* Copies kernel components to a flash card either from:
  * a linux kernel tree or
  * some other directory struct created by kern_cpy_local.sh
* Requires an SD card with a boot partition & root file system partitiion.
* Copies from the following directory structure to appropriate RPi file system

```
$BASE_DIR/lib/modules/
$BASE_DIR/boot/
$BASE_DIR/boot/dts/*.dtb
$BASE_DIR/boot/dts/overlays/*.dtb*
```
#### kern_cpy_local.sh

* Copies kernel components from a linux tree to some other location like a github repo
* Used to refresh the _kern_ directory in the repo

#### kern_cpy_remote.sh

* Requires a network connection to a remote machine
* Reference only, haven't used it in a while so probably doesn't work.
