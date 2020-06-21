## To Install ardopc for use with ARIM or PAT

```
cd
cd n7nix/ardop
./ardop_install.sh
```
* _ardop_install.sh_ script will install:
  * piARDOP_GUI
  * piardop2
  * piardopc
  * arim
* _ardop_install.sh_ script will __NOT__ install:
  * PAT
    * Install PAT with script found [here](https://github.com/nwdigitalradio/n7nix/tree/master/email/pat)

#### You must setup your alsa settings
* ARDOP installation was tested on VHF first
###### VHF radio: Kenwood TM-V71a ``` setalsa-tmv71a.sh ```

* Once ARDOP on VHF was confirmed, switched to __HF__ with these supported radios

###### ICOM IC-706MKIIG: ``` setalsa-ic706.sh ```
###### ICOM IC-7000 ``` setalsa-ic7000.sh ```
###### ICOM IC-7300 ``` setalsa-ic7300.sh ```
###### Elecraft KX2/KX3 ``` setalsa-kx2.sh ```

#### Running ARDOP with ARIM or PAT

There are two ways to start up ARDOP to be used with another application

#### 1. Start each process in a separate console
* Use this method to debug a broken configuration
  * Allows seeing all debug output at the same time
  * Follow this link: [Run manually with processes in separate consoles](MANUAL_STARTUP.md)

#### 2. Start all processes with Systemd Service Files
* This is the preferred way to start ARDOP
  * automatically starts process from boot
  * Follow this Link: [Run automatically with systemd service files](AUTO_STARTUP.md)
