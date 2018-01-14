## Notes on building a custom kernel or RPi and coping to proper director.

#### build.sh

* Displays tools version & git branch being built
* uses udr_defconfig file
* modules are copied to ../lib/modules
* builds all files required to boot an RPi

After building a kernel you need to copy the kernel image & device tree & overlay files to
the boot partition and the modules to the root file system.

#### cpy_local_kern.sh

* Requires an SD card with a boot partition & root file system partitiion.

#### cpy_remote_kern.sh

* Requires a network connection