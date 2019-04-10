## DRAWS 8 Pin Auxiliary Connector
* Looking into connector, pin 1 is top right
  * Odd number pins are on top

|  Pin   |  RPi Function   |  Alt0    |    Alt1  |    Alt2   |   Alt3      |  Alt4    | Alt5  |
| :---:  |  :---------:    |  :---:   |  :---: |  :---: |  :---: |  :---: |  :---: |
|   7  |   BCM22/Ain2    | SD0 CLK  | SMI SD14 |  DPI D18  |  SD1 CLK    |  JTAG TRST |        |
|   5  |   BCM24/Ain3    | SD0 DAT0 | SMI SD16 |  DPI D20  |  SD1 DAT0   |  JTAG TDO  |        |
|   3  |   BCM5          | GPCLK1   | SMI SA0  |  DPI D1   |  AVEOUT VID1 |  AVEIN VID1 | JTAG TDO |
|   1  |   Gnd           |          |          | | | | |
|   8  |  +5VDC @ 250 mA  | | | | | | |
|   6  |  Serial port Rx  | | | | | | |
|   4  |  Serial port Tx  | | | | | | |
|   2  |   BCM6          | GPCLK2   | SMI SOE_N/SE | DPi D2  |  AVEOUT VID2 |  AVEIN VID2 | JTAG RTCK |


### From Anna 12/16/2018

* The DRAWS has an ADC built into it.
  * You are correct that those are brought out on pins _Ain2_ and _Ain3_
  * You can access the values of these in a variety of ways through the [lmsensors/hwmon](https://github.com/lm-sensors/lm-sensors) subsystem in linux.
  * If you type _sensors_ on a running system, you'll get something that looks like this:

```
ads1015-i2c-1-48
Adapter: bcm2835 I2C adapter
User ADC Differential:  +0.00 V
+12V:                  +12.02 V
User ADC 1:             +0.01 V
User ADC 2:             +0.00 V
```

* The __+12V__ input is hooked to the DC input of the DRAWS.
* You can do various scaling on the User ADC values by using the sensors configuration file for DRAWS located at /etc/sensors.d/draws.
* Note that there are also some scaling factors available as __dtparam__ settings in config.txt.

* These pins are also connected to pins 22 and 24 on the Broadcom SoC for doing digital inputs or outputs.
*  Incidentally these are the __BCM__ pin numbers.
  *  You'll *never* hear me referring to wiringPi's pin numberings.

I'll let Bryan speak to the electrical characteristics of these pins, but I'm sure that if you try to measure a few thousand volts on them you'll have a bad day.

### From Bryan 04/09/2019
* The I/O pins are passed thru a 33ohm resistor and an ESD diode for protection

> Also I noticed on there that one of the pins is labeled rx and one is labeled tx.  Do those forward through to the serial port on the raspberry pi, or are they for something else?

* They do not connect to the /dev/ttyAMA0 port on the Pi.
  *  We don't bring that out on draws.
  *  They connect to an additional serial port, /dev/ttySC1, which is on the I2C serial chip we use to access the GPS.
  * ttySC0 used by GPS.
  * ttySC1 available serial port on Aux connector
