# How to use measure_deviate.sh

* This script creates an audio tone that can be used to help set FM deviation for your radio.
* Please read [this excellent write up from John Ackermann N8UR](https://www.febo.com/packet/layer-one/transmit.html)

#### Usage: measure_deviate.sh [-f _tone_frequency_ ][-c _connector_location_ ][-l _tone_duration_ ][-d][-h]
```
 -f, --frequency
        tone frequency in Hz (10 - 20000), default: 2200
 -c, --connector
        connector location either left (mDin6) or right (hd15/mDin6), default: right
 -l, --length
        length of tone in seconds, default 30
 -d, --debug
        no arg, set debug flag for more verbose console output
 -h, --help
        no arg, display this message
```

### Program Requirements ###
* direwolf must **NOT** be running
```
cd ~/bin
sudo su
./ax25-stop
```
* This script uses [gpio](http://wiringpi.com/), [sox](http://sox.sourceforge.net/) & [aplay](http://linuxcommand.org/man_pages/aplay1.html)
* To install sox, aplay & gpio
  * As root run the following:
```bash
apt-get install alsa-utils sox wiringpi
```
### Use ###

* Use measure_deviate.sh to generate a reference tone
* Use [HowTo:Set Deviation via RTL](https://xastir.org/index.php/HowTo:Set_Deviation_via_RTL) to measure FM transmitter deviation.
* The measure_deviate.sh script can be used to verify PTT & transmit path.
 *  Listen for the generated tone using another radio.

### Notes ###

* The script will run as long as the wavefile is playing.
* You can stop the script at any time by hitting _ctrl-c_

* You should be able to run the script without being root
  * Make sure you are in groups gpio & audio

```bash
groups
```

* If you need to add yourself to a group then as root
```bash
usermod -a -G audio <your_user_name>
usermod -a -G gpio <your_user_name>
```

* You will need to log back in to have groups take effect.

```bash
su <your_user_name>
# now verify
groups
```

* The script doesn't bother to check for length of wave files so if
you decide to change the duration of the tone, delete that tone file first.

### Debug notes ###

* If you want more excessive console output be sure to set the **-d**
flag on the command line.

* If PTT is working but you are not getting any audio:
  *  run __alsamixer__ and verify that **LOL Outp** and **LOR Outp** are
enabled.
    * **LOL Outp** and **LOR Outp** are enabled if you see 00 in a box directly above them.
    * Toggle enable by hitting the letter __m__

* The alsamixer levels are dependent on which radio you have.
* For setting your transmit output level (deviation):
  * 'Lo Drive' is the analog control and the preferred way to set level.
  * 'PCM' is the digital control & will set how many bits the DAC will use.

* **NOTE:** If you can't get close enough with the 'Lo Drive' control (doubtful) then use the 'PCM' control.

### Notes Alinco DR-x35 Mk III
```
PCM	        L:[0.00dB],  R:[0.00dB]
ADC Level	L:[-2.50dB], R:[-2.50dB]
LO Driver Gain  L:[11.00dB], R:[11.00dB]
```

### Notes Kenwood TM-V71a
```
$ ./alsa-show.sh
PCM	        L:[0.00dB],  R:[0.00dB]
ADC Level	L:[-2.00dB], R:[-2.00dB]
LO Driver Gain  L:[0.00dB],  R:[0.00dB]
```
