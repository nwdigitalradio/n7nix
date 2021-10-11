## How to provision a micro SD card with the NWDR image

#### Download the image file

* [Go to the download site](http:nwdig.net/downloads) to find the current filename of the image
  * **Note:** _current_image.xz_ and _nwdrxx.xz_ are **the same file**
    * checksum.txt contains the file size in bytes, md5sum & sha256sum
  * You can get the image using the following command or just click on the filename using your browser.
```bash
wget http://images.nwdigitalradio.com/downloads/current_image.img.xz
```
* **At least a 16GB microSD card is recommended**

##### How to verify the downloaded file
* If your SD card does not boot, you can verify your downloaded _nwdrxx.xz_ file by comparing information in the checksum.txt file:
  - File size
  - md5
  - sha256


* For Windows and MAC options for writing the image to the micro SD card go to the [Raspberry Pi documentation
page](https://www.raspberrypi.org/documentation/installation/installing-images/)
and scroll down to **"Writing an image to the SD card"**
* Most users use [balenaEtcher](https://www.balena.io/etcher/)

#### LINUX: Write image file to SD Card

##### Decompress the xz compressed image file
* Linux requires xz-utils package
* Windows requires WinZip, Easy 7-Zip or Windows Explorer, right click on file.
* Mac requires any of B1 Free Archiver, The Unarchiver, EZ 7z or 7zX

```bash
xz --decompress current_image.img.xz
```

##### Provision an SD card

* **For linux, use the Department of Defense Computer Forensics Lab
(DCFL) version of dd, _dcfldd_**.
  * **You can ruin** the drive on the machine you are using if you do not
  get the output device (of=) correct. ie. below _/dev/sdf_ is just an
  example.
  * There are good notes [here for Discovering the SD card mount
  point](https://www.raspberrypi.org/documentation/installation/installing-images/linux.md)

* After decompressing current_image.img.xz file you will find an image file: current_image.img

```
# Become root
sudo su
apt-get install dcfldd

# Use name of decompressed file ie. current_image.img
time (dcfldd if=current_image.img of=/dev/sdf bs=4M status=progress; sync)
# Doesn't hurt to run sync twice
sync
```

* The reason I time the write is that every so often the write completes in
around 2 minutes and I know a *good* write should take around 11
minutes on my machine.
