## Notes on building a custom kernel or RPi and coping to proper director.

#### build.sh

* Displays tools version & git branch being built
* uses udr_defconfig file
* modules are copied to ../modules_install
* builds all files required to boot an RPi

#### cpy_local_kern.sh

* Requires an SD card

#### cpy_remote_kern.sh

* Requires a network connection