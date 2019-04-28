## Running FLdigi with the Yaesu FT-817

### Radio Configuration
#### Set Radio for Digital Mode Operation (SSB-Based AFSK)

* Use a mDin6 cable **without** pin 6, Squelch connected (I wiggled pin 6 until it broke)
  * Looking into the male mDin 6 connector with the key on top, its the upper right hand pin
  * Verify this as it is easy to get it wrong

##### Setup "USER" defined digital mode
* Please refer to your Yaesu manual _"Digital Mode Operations (SSB-Based AFSK)"_

* Menu #24 DIG DISP: display shift
  * 0 Hz
* Menu #25 DIG MIC: AFSK drive level
  * 61
* Menu #26 DIG MODE: User defined digital mode
  * USER-U
* Menu #27 DIG SHIFT: transceiver passband response
  * 0 Hz

### RPi - ALSA Configuration

* Run _setalsa-ft817.sh_ which sets alsa config to the following:
  * Note that this selects the received signal on mDin6 pin 5, AFOUT

```
===== ALSA Controls for Radio Tansmit =====
LO Driver Gain  L:[-6.00dB]	R:[-6.00dB]
PCM	        L:[-16.50dB]	R:[-16.50dB]
DAC Playback PT	L:[PTM_P3]	R:[PTM_P3]
LO Playback CM	[Full Chip CM]

 ===== ALSA Controls for Radio Receive =====
ADC Level	L:[-2.00dB]	R:[-2.00dB]
IN1		L:[Off]		R:[Off]
IN2		L:[10 kOhm]	R:[10 kOhm]
```
* PT = PowerTune
* CM = Common Mode

* Run _alsa-show.sh_ to verify

### FLdigi Configuration
* There are some very good [FLdigi instructions for the udrc here](https://nw-digital-radio.groups.io/g/udrc/wiki/UDRC%E2%84%A2-and-fldigi-Setup-Page)
  * These instructions differ for the DRAWS HAT:
    * FLdigi has already been downloaded & built on the DRAWS image
    * DRAWS swapped the PTT gpio settings for left & right connector compared to UDRC II.
* Run FLdigi by using the main desktop menu (upper left corner of desktop) > Internet > Fldigi
* These instructions are for FLdigi controlling the PTT with the RPi GPIO
  * RigCat or FlRig are not used.

###### Select Configure > Soundcard
* Select the Devices tab:
  * Select **PortAudio** and deselect all others
  * The following assumes that the internal RPi sound device is not enabled
    * Select udrc: - (hw:0,0) for both Capture and Playback

######  Select Configure > Rig Control
    Left  Channel PTT gpio is BCM 12
    Right Channel PTT gpio is BCM 23

######  Select Configure > Sound Card > Audio > Right Channel

* To select the Right Channel tab do the following:
  * Check the reverse left/right channels checkbox for both Transmit & Receive
* To select the Left Channel do the following:
  * **Clear** the reverse left/right channels checkbox

###### Select Op Mode
* ie for Olivia 8-250
  * Op Mode > Olivia > OL 8-250

#### For FLdigi do **NOT** set Radio for Packet (1200/9600 bps FM) Operation

## Running packet apps with the Yaesu FT-817
### Radio Options
#### Set Radio for Packet 1200/9600 bps FM Operations
* Please refer to your Yaesu manual _"Packet 1200/9600 bps FM Operations"_

* Menu #39 (PKT MIC) allows adjusting drive level.
* Menu #40 (PKT RATE) to select AFOUT(1200 bps) or DISCOUT (9600 bps)

* Note different connections are used for 1200 & 9600 (AFOUT & DISCOUT)
* If you are having trouble connecting due to insufficient or excessive drive from the TNC to the FT-817
  * use Menu #39 (PKT MIC) to set the drive. for 1200/9600 BPS FM packet, Page 41
  * Depends on DIG MODE setting: RTTY, PSK31-L or -U, USER-L or -U
    * -L lower side band, -U upper side band
    * use Menu #25 (Dig MIC) to adjust DATA input level for PSK, Page 22

* Use some "test" protocol to send out test tones and adjust the
deviation by rotating the DIAL knob, which will vary the data input
level to the FT-817's modulator. Remember to press and hold in the F
key for one second when adjustments are completed, so as to save the
new setting for Menu #39

#### RPi
* ALSA settings
  * Use IN1_L IN1_R for 9600 baud (DISCOUT)
  * Use IN2_L IN2_R for 1200 baud or less (AFOUT)

## ALSA settings for IC-7000

#### From the IC-7000 manual page 116
*  adjust the TX audio level (data in level) from the TNC as follows.
  * 0.4 Vp-p (0.2 Vrms): recommended level
  * 0.2-0.5 Vp-p (0.1-0.25 Vrms): acceptable level
* When in packet mode route RX Audio to pin 4 DATA OUT (discriminator)
  * Select IN1 (L & R) 10 kOhm (or 20 & 40 kOhm) in alsamixer
* While testing with FLdigi it was noticed that the tones where cleaner when routing through the discriminator.
* The IC-7000 presents the received signal on both pin 4 DISCOUT & pin 5 AFOUT

### RPi - ALSA Configuration
* Run _setalsa-ic7000.sh_ which sets alsa config to the following:


###### Transmit
* ALSA control _DAC Playback Power Tune_ set to PTM_P1
* Same LO Drive Gain & PCM settings as Yaesu FT-817

###### Receive
* Make sure the preamp is turned off.
  * _P.AMP/ATT_ button to left of screen
* Select received signal on mDin6 pin 4, DISCOUT


###### Summary

```
===== ALSA Controls for Radio Tansmit =====
LO Driver Gain  L:[-6.00dB]	R:[-6.00dB]
PCM	        L:[-16.50dB]	R:[-16.50dB]
DAC Playback PT	L:[PTM_P1]	R:[PTM_P1]
LO Playback CM	[Full Chip CM]

 ===== ALSA Controls for Radio Receive =====
ADC Level	L:[-2.00dB]	R:[-2.00dB]
IN1		L:[10 kOhm]	R:[10 kOhm]
IN2		L:[Off]		R:[Off]
```

