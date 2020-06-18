## To Install ardopc & arim

```
cd
cd n7nix/ardop
./ardop_install.sh
```
#### You must setup your alsa settings
* ARDOP installation was tested on VHF first
###### VHF radio: Kenwood TM-V71a ``` setalsa-tmv71a.sh ```
* Once ARDOP on VHF was confirmed, switched to HF

###### HF radio: ICOM IC-706MKIIG: ``` setalsa-ic706.sh ```
###### HF radio: ICOM IC-7300 ``` setalsa-ic7300.sh ```
###### HF radio: Elecraft KX2/KX3 ``` setalsa-kx2.sh ```

* [Run manually with processes in separate consoles](MANUAL_STARTUP.md)
* [Run automatically with systemd service files](AUTO_STARTUP.md)

