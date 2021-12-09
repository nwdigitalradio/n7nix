## Enable Audio alerts for Xastir

* If you are using a NWDR image and install files then most of what is described below is already done
  * When using the image you should only need to:
    - Verify there are wave sound files in /usr/share/xastir/sounds
    - Determine the audio device that Xastir will use
      * ```aplay -l```
    - Test audio device from console with audio device ie. card 0 device is _plughw:0,0_
      * ```aplay -D "plughw:0,0" /usr/l/share/xastir/sounds/bandopen.wav```
    - Put proper command in File -> Configure -> Audio Alarms -> Audio Play Command
    - Initially, **enable all alarms in "Alarm on" list**

### How to determine an audio device to use

* Run _aplay -l_ and choose the most likely device.
  * From the list below:
    * Card 0 is the HDMI device - you might use this if the speaker is embedded in your display.
      * Device name is ```plughw:0,0```
    * Card 1 is the on-board RPi audio device <- **probably what you want to use**
      * Device name is ```plughw:1,0```
    * Card 2 is the UDRC codec and **NOT** what you want to use.
      * Device name is ```plughw:2,0```

```
aplay -l
**** List of PLAYBACK Hardware Devices ****
card 0: b1 [bcm2835 HDMI 1], device 0: bcm2835 HDMI 1 [bcm2835 HDMI 1]
  Subdevices: 4/4
  Subdevice #0: subdevice #0
  Subdevice #1: subdevice #1
  Subdevice #2: subdevice #2
  Subdevice #3: subdevice #3
card 1: Headphones [bcm2835 Headphones], device 0: bcm2835 Headphones [bcm2835 Headphones]
  Subdevices: 4/4
  Subdevice #0: subdevice #0
  Subdevice #1: subdevice #1
  Subdevice #2: subdevice #2
  Subdevice #3: subdevice #3
card 2: udrc [udrc], device 0: bcm2835-i2s-tlv320aic32x4-hifi tlv320aic32x4-hifi-0 [bcm2835-i2s-tlv320aic32x4-hifi tlv320aic32x4-hifi-0]
  Subdevices: 0/1
  Subdevice #0: subdevice #0
```

### Instructions for enabling audio if __NOT__ using an NWDR image

* Need to enable the RPi audio device
  * uncomment the following line in _/boot/config.txt_
```
# dtparam=audio=on
```
* The _Audio Play Command_ is different for analog & HDMI audio

* Download xastir sound files
```
git clone https://github.com/Xastir/xastir-sounds
cd xastir-sounds/sounds
cp *.wav /usr/share/xastir/sounds
```
* **Note:** audio device plughw:0,0 is for normal analog audio out
* File -> Configure -> Audio Alarms
  * _Audio Play Command_ for analog audio: aplay -D "plughw:0,0"
  * Select alerts: New Station, New Message, Proximity, Weather Alert

### HDMI audio
* [Follow this link for HDMI audio](#Instructions_if_using_an_HDMI_audio_device)


### Instructions if using an HDMI audio device
* Use this if you have an audio speaker in your video display.


* **Note:** audio device plughw:0,1 is for a Sunfounder LCD display with HDMI audio

* HDMI audio starts about 2 seconds delayed
  * Make a wave file that is 2 seconds of silence
  * Just use [silence.wav file in this repo](https://github.com/nwdigitalradio/n7nix/blob/master/xastir)
  * Put silence.wav in Xastir sounds directory /usr/share/xastir/sounds

  * _Audio Play Command_ for HDMI:

```aplay -D "plughw:0,1" /usr/share/xastir/sounds/silence.wav```

* To make a two second silent wave file execute the following on a computer with audio input
  * Make sure the microphone is not attached.
```
rec silence.wav trim 0 02
```

* Make sure audio is routed to HDMI
```
amixer cget numid=3
```
* If value is not equal to 2 then:
```
amixer cset numid=3 2
```
* Make sure audio for bcm 2835 chip is enabled in /boot/config.txt file
```
# Enable audio (loads snd_bcm2835)
dtparam=audio=on
```

### Verify Audio

* Find your active audio device by listing sound devices
```
aplay -l
```

* Verify active audio device by playing a wave file
```
cd /usr/share/xastir/sounds

# For Analog audio
aplay -D "plughw:1,0" bandopen.wav

# For HDMI audio
aplay -D "plughw:1,1" silence.wav bandopen.wav
```
* Run speaker test & listen for white noise
```
#  Speaker test for analog
speaker-test -D plughw:1,0 -c 2

# Speaker test for HDMI
speaker-test -D plughw:0,1 -c 2
```
