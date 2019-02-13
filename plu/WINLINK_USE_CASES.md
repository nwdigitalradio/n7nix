# Description of Use Cases for Winlink the DRAWS board

## 1. Embedded - No local monitor
* For sending daily reports using scripts
* Minimal install using console email client for Winlink
* Use with Linux RMS Gateway for a remote Winlink site.
* Use paclink-unix to control transport

## 2. Local email client using the RPi with a monitor
* Run claws-email client for composing & receiving Winlink messages
* Use paclink-unix to control transport

## 3. Remote email client using an RPi as a Host Access Point
* Using an RPi with WiFi capability compose Winlink messages with Android or Apple remote device.
* Using a Web interface to control paclink-unix transport

## 4. Use a Windows machine and the RPi as a TNC via TCP
* From Direwolf User Guide Kiss TNC emulation - network page 15

#### Winlink / RMS Express
* First start up Dire Wolf.
* Run Winlink Express.
* Next to _Open Session_, pick either _Packet Winlink_ or _Packet P2P_
* Click on _Open Session_
* In the _Packet ... Session_ window, click on _Settings_
* Set configuration like this:
  * Packet TNC Type: Kiss
  * Packet TNC Model: NORMAL
  * Serial Port: TCP
  * TCP Host/Port <ip_address_of_RPi> 8001