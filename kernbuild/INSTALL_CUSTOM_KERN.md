## Overview steps to install a modified kernel.

* get a root file system image
* copy onto flash part
* get a modified kernel
* copy onto flash part


### Get a root file system image

* Go to [this url](http://archive.compasslinux.org/images/wilderness/)
```
http://archive.compasslinux.org/images/wilderness/
```
##### if your RPi is NOT attached to a display
scroll to bottom & pick image_`<date>`-compass-lite.zip
#####  if you DO have a display
scroll to bottom & pick image_`<date>`-compass.zip

* unzip image
```
unzip image_<date>-compass-lite.zip
```

### copy image to flash part
  * you will need to have an ssh file name in boot partition to enable ssh on first boot.

* See flashit.sh script for reference
  *  **change flash_dev & img_date to suit**
  * Assumes:
    *  you can mount the fat32 partition at /mnt/fat32
    *  you can mount the ext4 partition at /mnt/ext4
```
time dd if=${img_date}-compass.img of=/dev/sde bs=1M status=progress
touch /mnt/fat32/ssh
```
##### For UDRX

* Add the following line to bottom of /boot/config.txt ie. /mnt/fat32/config.txt
```
dtoverlay=udrx
```

You can either test this image out now to see if it boots or proceed
to put a modified kerenel on the flash part

### copy modified kernel to flash part
```
umount /mnt/fat32
umount /mnt/ext4
# Clone my repo
git clone https://github.com/nwdigitalradio/n7nix
cd n7nix/kernbuild
# as root run
./kern_cpy_flash.sh
```

* You are done, install flash part on RPi & boot
