## ALSA Controls

* For a more detailed description of what these controls do please
read [ Audio CODEC Analog Routing, Digital Interfacing and
Controls](https://nw-digital-radio.groups.io/g/udrc/wiki/DRAWS%E2%84%A2-Audio-CODEC-Analog-Routing%2C-Digital-Interfacing-and-Controls)

* For a [YouTube video on setting values using TX Calc spreadsheet](https://youtu.be/RxWiDYMcRn4)
  * Download [TX Calc spreadsheet](https://nw-digital-radio.groups.io/g/udrc/files/TX%20Calc.xlsx) for setting ALSA controls

* DRAWS Manager is our web based program for setting the Controls --
it includes the TX Calculation function and direct setup of controls,
set [this video](https://www.youtube.com/watch?v=v5C3cWVVz_A)

### Transmit Controls that affect input to radio

| ALSA Control Name |  Values  | Function |
|     :---         |  :---   |  :---   |
| LO Driver Gain (L & R)       | 29 dB to -6dB in 1 dB steps | gain of the LO amplifier (analog) |
| LO Playback Common Mode      | Full Chip CM, 1.65V | Set power supply of LO amplifier |
| PCM (L & R)                  | 24 dB to -63.50 dB in half dB steps | Output level from DAC (digital |
| DAC Right Playback PowerTune | PTM_P1, PTM_P2, PTM_P3 | Set power mode, PTM_P3 is highest |
| DAC Left  Playback PowerTune | PTM_P1, PTM_P2, PTM_P3 |


### Receive Controls that affect output from radio

| ALSA Control Name |  Values  | Function |
|     :---         |  :---   | :--- |
| ADC Level (L & R) |   20dB to -12dB in half dB steps | input level of both ADCs |
| IN1_L to Left Mixer positive Resistor     | Off, 10, 20 or 40 kOhm | resistor ctrl on path from IN1_L to Left Mixer |
| IN1_R to Right Mixer positive Resistor    | Off, 10, 20 or 40 kOhm | resistor ctrl on path from IN1_L to Right Mixer |
| IN2_L to Left Mixer positive Resistor     | Off, 10, 20 or 40 kOhm | resistor ctrl on path from IN2_L to Left Mixer |
| IN2_R to Right Mixer positive Resistor    | Off, 10, 20 or 40 kOhm | resistor ctrl on path from IN2_L to Right Mixer |
| CM (L & R)                                | Off, 10, 20 or 40 kOhm | resistor ctrl on path for Common Mode |

### Programs to View & Set ALSA controls

##### alsamixer
* _alsamixer_ provides an ncurses graphical interface to set ALSA control values.

##### amixer

* _amixer_ provides command-line control for ALSA soundcard mixer suitable for scripting ALSA control values.


##### alsa-show.sh
* Script to view a condensed output of ALSA controls
  * Parses amixer output to display the most commonly used controls
  * Example output of default configuration:
```
 ===== ALSA Controls for Radio Tansmit =====
LO Driver Gain  L:[-6.00dB]	R:[-6.00dB]
PCM	        L:[-25.00dB]	R:[-25.00dB]
DAC Playback PT	L:[PTM_P3]	R:[PTM_P3]
LO Playback CM	[Full Chip CM]

 ===== ALSA Controls for Radio Receive =====
ADC Level	L:[0.00dB]	R:[0.00dB]
IN1		L:[Off]		R:[Off]
IN2		L:[10 kOhm]	R:[10 kOhm]
CM		L:[10 kOhm]	R:[10 kOhm]
```

##### Programs to set up initial ALSA controls

###### For DRAWS HAT

* setalsa-default.sh
* setalsa-ft817.sh
* setalsa-ft817.sh
* setalsa-ic7000.sh
* setalsa-tmv71a.sh


###### For UDRC II HAT
* setalsa-udrc-alinco.sh
* setalsa-udrc-din6.sh
* setalsa-dr1x.sh
* setalsa-not-dr1x.sh
