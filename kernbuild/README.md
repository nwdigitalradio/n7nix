## Notes on building a custom kernel or RPi and coping to proper director.

#### build.sh

* Displays tools version & git branch being built
* uses udr_defconfig file
* modules are copied to ../lib/modules
* builds all files required to boot an RPi

After building a kernel you need to copy the kernel image & device tree & overlay files to
the boot partition and the modules to the root file system.

#### kern_cpy_flash.sh

* Copies kernel components from a linux kernel tree or some other directory struct to a flash card
* Requires an SD card with a boot partition & root file system partitiion.
* Copies from this directory structure to appropriate RPi file system

```
$BASE_DIR/lib/modules/
$BASE_DIR/boot/
$BASE_DIR/boot/dts/*.dtb
$BASE_DIR/boot/dts/overlays/*.dtb*
```
#### kern_cpy_local.sh

* copies kernel components from a linux tree to some other location like a github repo

#### kern_cpy_remote.sh

* Requires a network connection
