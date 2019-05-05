## Steps to take if you have problems

#### Before you run any scripts from a fresh image verify the image written to SD card

##### Verify SD card was written to
* Checks to see if there is an old config on the SD card
```
cd
cd n7nix/config
./cfgcheck.sh

# You should see something like this:
-- app_config.sh core script has NOT been run: hostname: 1, passwd: 1, logfile: 1
```

##### Verify the driver was loaded properly
* There are a couple of things that cause the driver to not load
  * On-board BCM2835 audio driver loaded before udrc driver
  * AudioSense-Pi sound card driver prevents udrc driver from loading

###### Verify driver running properly by running aplay -l
```
aplay -l

# You should see something like this
**** List of PLAYBACK Hardware Devices ****
card 0: ALSA [bcm2835 ALSA], device 0: bcm2835 ALSA [bcm2835 ALSA]
  Subdevices: 7/7
  Subdevice #0: subdevice #0
  Subdevice #1: subdevice #1
  Subdevice #2: subdevice #2
  Subdevice #3: subdevice #3
  Subdevice #4: subdevice #4
  Subdevice #5: subdevice #5
  Subdevice #6: subdevice #6
card 0: ALSA [bcm2835 ALSA], device 1: bcm2835 ALSA [bcm2835 IEC958/HDMI]
  Subdevices: 1/1
  Subdevice #0: subdevice #0
card 1: udrc [udrc], device 0: Universal Digital Radio Controller tlv320aic32x4-hifi-0 []
  Subdevices: 1/1
  Subdevice #0: subdevice #0
```

* If you do **not** see __udrc__ in the _aplay -l_ output
  * For **BETA12** images or later run these scripts and reboot
```
chk_conflict.sh
chk_bootcfg.sh
```
* **After you reboot** verify by running _aplay -l_ again.
* For images newer than **BETA12** ie. BETA13, congratulations you have discovered a new problem
  * Please post a description of the problem.


#### Post your problem.

* Describe your problem and answer these questions:
- Did you make your own cables?
- Which mDin6 connector are you using?
  * Looking at the front of the connector __left__ or __right__
- What program & program version are you running that gives the symptoms you described?
- What is the make & model number of your radio?

* Include the console output of:
  - Complete console output of install by running _script_ program before first configuration script
  - Console output of _showudrc.sh_ script
    * Run this script to display information about your system.
    * Cut & paste the console output to the forum or in an email
```
showudrc.sh
```



###### Capture Console Output Instructions
  * _script_ captures everything output to your terminal in a file
```
script ~/tmp/install_boot1.txt
# You should see something like this:
Script started, file is /home/pi/tmp/install_boot1.txt
```
* **Before you reboot** - close the _script_ output file
```
# After the install script has completed type exit until you see something like:
exit
Script done, file is /home/pi/tmp/draws_install.txt
```

* If you reboot follow the _capture console output instructions_ again but use _install_boot2.txt_ as the output file.
  * Change the _install_bootx.txt_ filename after each reboot.
  * Attach these files to your problem report email.
* Now Follow the instructions from [Getting Starting Guide](https://nw-digital-radio.groups.io/g/udrc/wiki/DRAWS%3A-Getting-Started)

### Web links to instructional videos

* [DRAWS Manager Video](https://www.youtube.com/watch?v=v5C3cWVVz_A)
* [DRAWS GPS & FT8](https://www.youtube.com/watch?v=5lxvVD1-0lk)