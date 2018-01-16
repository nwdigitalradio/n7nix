## Overview steps to install a modified kernel

All of the steps take place on a Linux workstation. The first step
is to plug a 16GB flash part into your flash reader and the last
step is to unplug the flash part & install it in your Raspberry
Pi.

* Get a root file system image
* Copy image to flash part
* Get a modified kernel
* Copy modified kernel to flash part


### Get a root file system image

* Go to [this url](http://archive.compasslinux.org/images/wilderness/) and download a zipped image.
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

### Copy image to flash part
  * you will need to have an ssh file name in boot partition to enable ssh on first boot.

* See [flashit.sh script](https://github.com/nwdigitalradio/n7nix/blob/master/kernbuild/flashit.sh) for reference
  *  **Need to modify these variables: flash_dev & img_date to suit**
  * **WARNING: Verify variable flash_dev in flashit.sh is in fact the flash device!**
    * **if it isn't you can hose your workstation**

  * Assumes:
    * You can mount the fat32 partition at /mnt/fat32
    * flashit.sh script is in same directory as image directory
    * Run as root
```
time dd if=${img_date}-compass.img of=/dev/sde bs=1M status=progress
mount ${flash_dev}1 /mnt/fat32
touch /mnt/fat32/ssh
umount /mnt/fat32
```
* Be patient, this will take a while if you are flashing the non compass-lite version.
  * On the other hand if it doesn't take several minutes then the copy propably didn't work.
* Output from flashing full compass version using flashit.sh script
```
4410310656 bytes (4.4 GB, 4.1 GiB) copied, 9.00687 s, 490 MB/s
4247+0 records in
4247+0 records out
4453302272 bytes (4.5 GB, 4.1 GiB) copied, 522.557 s, 8.5 MB/s

real	8m42.560s
user	0m0.012s
sys	0m5.696s

Finished flashing part
```

##### For UDRX

* Add the following lines to bottom of /boot/config.txt ie. /mnt/fat32/config.txt
```
force_turbo=1
dtoverlay=udrx
```
* Also uncomment this line in the same file
```
#dtparam=spi=on
```

You can either test this image out now to see if it boots or proceed
to put a modified kernel on the flash part

### Get a modifed kernel
* The modified kernel exists in this repo in the _kern_ directory.
* Run git as user not root.
```
# Clone repo as user
git clone https://github.com/nwdigitalradio/n7nix
```

### Copy modified kernel to flash part
```
umount /mnt/fat32
umount /mnt/ext4
cd n7nix/kernbuild
```
* **WARNING: Verify variable flash_dev in kern_cpy_flash.sh is in fact the flash device!**
  * **if it isn't you can hose your workstation**

  * Assumes:
    * You can mount the fat32 partition at /mnt/fat32
    * You can mount the ext4 partition at /mnt/ext4
    * Run as root in same directory as directory _kern_
      *  ie. run it from the cloned repo

```
./kern_cpy_flash.sh
```

* You may see a bunch of errors like the following, please ignore:
```
rsync: chown "/mnt/fat32/.bcm2708-rpi-0-w.dtb.Lj0j5p" failed: Operation not permitted (1)
rsync: chown "/mnt/fat32/overlays/.adau1977-adc.dtbo.X6QxJg" failed: Operation not permitted (1)
```

* You are done, install flash part on RPi & boot
  * To verify that you are running a custom kernel:
```
cat /proc/version
```
* You should see something similar to this:
```
Linux version 4.9.35-v7+ (gunn@beeble) (gcc version 4.9.3 (crosstool-NG crosstool-ng-1.22.0-88-g8460611) ) #2 SMP Sun Jan 14 09:14:32 PST 2018
```
* Not this:
```
Linux version 4.9.35-v7+ (jenkins@jenkins) (gcc version 5.4.0 20160609 (Ubuntu/Linaro 5.4.0-6ubuntu1~16.04.4) ) #1 SMP Sun Dec 31 13:00:49 PST 2017
```
