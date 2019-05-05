## Notes & links to manuals for some HAM radios

### IC-706MKIIG

* [IC-706MKIIG](http://www.icom.co.jp/world/support/download/manual/pdf/IC-706MK2G.pdf)

##### 6 pin mini Din connector

* **NOTE:** For packet operation the transceiver can be set to one of
two data speeds: 1200 bps or 9600 bps. Data speed is set in initial
set mode (see p. 54 item 29 9600 MODE).

###### Recommended audio level

* When using a level meter or synchroscope, adjust the TX audio level (DATA IN level) from the TNC as follows:
  * 0.4 Vp-p (0.2 Vrms): recommended level
  * 0.2 Vp-p 0.5 Vp-p (0.1 Vrms 0.25 Vrms): acceptable level

|  PIN  | Name  | Description |
| :---: | :---: | :---        |
|   1   | Data in | Communications data input |
|   2   | Gnd     | Ground for Data in, Data OUT & AF OUT |
|   3   | PTTP    | Transmits when grounded  |
|   4   | Data OUT | Outputs 9600 bps receive data |
|   5   | AF OUT   | Outputs 1200 bps receive data |
|   6   | SQ       | Squelch output, goes to ground when squelch opens |

### IC-7000

* [IC-7000 Instruction Manual](https://www.icomamerica.com/en/downloads/DownloadDocument.aspx?Document=165)

### IC-7300

* [IC-7300 Basic Manual](https://www.icomamerica.com/en/downloads/DownloadDocument.aspx?Document=784)

### Yaesu FT-891
* [FT-891 Operating Manual](https://www.yaesu.com/airband/downloadFile.cfm?FileID=11695&FileCatID=158&FileName=FT%2D891%5FOM%5FENG%5FEH065H201%5F1611A%2DBO%2D2.pdf&FileContentType=application%2Fpdf)
* [FT-891 Advance Manual](https://www.yaesu.com/airband/downloadFile.cfm?FileID=14759&FileCatID=158&FileName=FT%2D891%5FAdvance%5FManual%5FENG%5F1806%2DF.pdf&FileContentType=application%2Fpdf)

### Yaesu FT817 & FT-817nd
* [FT-817nd Operating Manual](https://www.yaesu.com/downloadFile.cfm?FileID=8032&FileCatID=158&FileName=FT%2D817ND%5FOM%5FENG%5FE13771011.pdf&FileContentType=application%2Fpdf)

|  PIN  |    Pin Label   | ALSA  | Note |
| :---: | :---:          | :---: | :--- |
|  1    |  DATA IN       |       | Max input level 40mV pp @1200bps, 1.0V pp @9600bps |
|  2    |  GND           |       |  |
|  3    |  PTT           |       | Ground to xmit |
|  4    |  Data out 9600 | LIN1  | Discout Max output level 500mVpp, Impedance 10k ohms |
|  5    | Data out 1200  | LIN2  | AFOUT Max output level 200mVpp, Impedance 10k ohms |
|  6    | SQL            |       | SQL open: 5v, SQL Closed: 0V  |


### Yaesu FT-818nd

* [FT-818nd Operating Manual](http://www.yaesu.com/downloadFile.cfm?FileID=8032&FileCatID=158&FileName=FT-817ND_OM_ENG_E13771011.pdf&FileContentType=application.pdf)


### Kenwood TM-V71A

* [Kenwood TM-V71A](http://manual.kenwood.com/files/494077600f426.pdf)
  * See page 83

|  PIN  | Name   |  I/O   | Note |
| :---: | :---:  | :---:  | :--- |
|  1    |  PKD   | Input  | Audio signal for packet transmission |
|  2    |  DE    |   -    | PKD terminal ground |
|  3    |  PKS   | Input  | 'L' is transmitted and the mike is muted |
|  4    |  PR9   | Output | 9600 (bps) repeat signal |
|  5    |  PR1   | Output | 1200 (bps) repeat signal |
|  6    |  SQC   | Output | Squelch control signal; Closed: 'L', Open: 'H' |

* Default settings for squelch can be changed in Menu 520
* Data terminal speed Menu 518 (DAT.SPD)
  * 1200 bps: Transmit data input (PKD) sensitivity is 40mVp-p, input impedance is 10K ohms
  * 9600 bps: Transmit data input (PKD) sensitivity is 2Vp-p, input impedance is 10K ohms
