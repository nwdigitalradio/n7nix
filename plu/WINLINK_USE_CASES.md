# Use Cases for Winlink and the DRAWS board


## Local Monitor Required

### 1. Local email client using the RPi and an Internet connection
* Run claws-email client for composing & receiving Winlink messages
* Use all paclink-unix transports

### 2. Local email client using the RPi and __NO__ Internet connection
* Run claws-email client for composing & receiving Winlink messages
* Use paclink-unix transports wl2kax25, wl2kserial

## No Local Monitor Required

### 3. Embedded - No local monitor required, Internet connection __IS__ required.
* For sending daily reports using scripts or as a remote Winlink client.
* Minimal install using console email client for Winlink
* Use with Linux RMS Gateway for a remote Winlink site.
* Use all paclink-unix transports

### 4. Remote email client, __NO__ Internet required
* Use an RPi with WiFi capability to compose Winlink messages with Android or Apple mobile device.
* Use a Web interface to control paclink-unix transports
* If there is no Internet connection a DNS server & host AP on the RPi is required.
* Use paclink-unix transports wl2kax25, wl2kserial

### 5. Use a Windows machine and the RPi with direwolf as a TNC via TCP, __NO__ Internet required
* From Direwolf User Guide Kiss TNC emulation - network page 15
* If there is no Internet connection a DNS server & host AP on the RPi is required.
* Does __NOT__ use paclink-unix

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
