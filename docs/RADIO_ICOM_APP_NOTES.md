## Running FLdigi with ICOM IC-706MkIIG

#### Cables
* [USB CI-V Cat Interface Cable For Icom CT-17 IC-706](https://www.amazon.com/Interface-Cable-IC-706-Works-Desktops-Laptops/dp/B008MTQZCS)
  * Plugs into CI-V remove control jack on back of IC-706
* [ICOM 13 PIN DIN ACC PORT TO NW DIGITAL DRAWS HAT 6 PIN MINI DIN PACKET PORT PLUG](https://hammadeparts.com/shop-for-cables/ols/products/icom-13-pin-din-acc-port-to-nw-digital-draws-hat-6-pin-mini-din-packet-port-plug)
  * Plugs into Accessory Socket [ACC] on back of IC-706

#### Config for FLrig
*  Config > Xcvr
  * Rig: IC-706MKIIG
  * Update: /dev/ttyUSB0
  * Baud: 19200
* Config > GPIO
  * Check: Use GPIO PTT
  * Check: BCM 12 & On


#### Config for FLdigi

* Configure > Operator Station
  * Fill in all config
* Configure > Rig Control > flrig
  * check Enable flrig xcvr control with fldigi as client
  * check Flrig PTT keys modem

* Turn SQL knob clock wise until blue waterfall displays.
  * On bottom row of buttons hit x1 to change to x2 for a 0-3k display
* Fldigi normally displays 0 - 3000 hz on the waterfall.