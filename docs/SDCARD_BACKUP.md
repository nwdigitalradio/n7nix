# How to make an SD card image backup

## Using Linux


##### Requirements
###### dcfldd
* [dcfldd](http://dcfldd.sourceforge.net/)
```
sudo apt-get install -y dcfldd
```
###### pishrink.sh
* [PiShrink](https://github.com/Drewsif/PiShrink)

```
wget https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh
chmod +x pishrink.sh
sudo mv pishrink.sh /usr/local/bin
```

##### Determine if there enough room on your hard drive
* You are about to write a couple of very large files to your system disk
  * Is there enough room?
```
df -h
```
* For example look in the _Mounted on_ column for a forward slash "/"
  * There are two devices listed below, a 500GB SSD & and a 1TB hard drive
```
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
udev             16G     0   16G   0% /dev
tmpfs           3.2G  1.6M  3.2G   1% /run
/dev/sda1       427G  261G  145G  65% /
tmpfs            16G  248M   16G   2% /dev/shm
tmpfs           5.0M  4.0K  5.0M   1% /run/lock
tmpfs            16G     0   16G   0% /sys/fs/cgroup
/dev/sdb1       916G  272G  599G  32% /media/backup
tmpfs           3.2G   68K  3.2G   1% /run/user/1000
```

##### Determine device name of SD card device
* Use lsblk
  * Probably the last entry in list

* For example on my Linux workstation the SD card device is _sde_
```
$ lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda      8:0    0 465.8G  0 disk
  sda1   8:1    0 433.9G  0 part /
  sda2   8:2    0     1K  0 part
  sda5   8:5    0  31.9G  0 part [SWAP]
sdb      8:16   0 931.5G  0 disk
  sdb1   8:17   0 931.5G  0 part /media/backup
sde      8:64   1   7.4G  0 disk
  sde1   8:65   1   256M  0 part /media/gunn/boot
  sde2   8:66   1   7.1G  0 part /media/gunn/rootfs
```
* Confirm SD card device name
```
dmesg | tail | grep "sd "
```
* For example on my workstation the SD card device is _/dev/sde_
```
$ dmesg | tail | grep "sd "
[8981514.397228] sd 6:0:0:2: [sde] 15523840 512-byte logical blocks: (7.95 GB/7.40 GiB)
```

##### Read image from SD card device /dev/sde and create a file
```
sudo dcfldd if=/dev/sde of=back-up_image_file_name
sync
```
##### Create compressed image of SD card file system
```
sudo pishrink.sh -z back-up_image_file_name compressed_image.img
```


## Using MAC

[ApplePi-Baker v2 - Backup & Restore SD cards, USB drives, etc.](https://www.tweaking4all.com/hardware/raspberry-pi/applepi-baker-v2/)

## Using Windows

* Please read this thread, [Back Pi Image and Clone SD Card](https://groups.io/g/RaspberryPi-4-HamRadio/topic/back_pi_image_and_clone_sd/72610766?p=,,,20,0,0,0::recentpostdate%2Fsticky,,,20,2,0,72610766)
  * You may have to join the [RaspberryPi-4-HamRadio group](https://groups.io/g/RaspberryPi-4-HamRadio)