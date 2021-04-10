## Manual Setup of a fresh NWDR image
* All of the following steps are done in the _initcfg.sh_ script.
  * **Preferred initial config is done using the _initcfg.sh_ script**

#### Initial Config Summary

- 1: First boot:
  - Verify that required drivers for the DRAWS codec are loaded.
  - Update the configuration scripts
  - Follow 'Welcome to Raspberry Pi' piwiz screens.
- 2: Second boot: run script: ```app_config.sh core```
- 3: Third boot: Set your ALSA config
- 4: For packet turn on Direwolf & AX.25

### 1. First boot

#### Check for required drivers first
* Open a console and type:
```
aplay -l
```
* You should see a line in the output that looks something like this:
```
card 0: udrc [udrc], device 0: bcm2835-i2s-tlv320aic32x4-hifi tlv320aic32x4-hifi-0 []
```

* If you do **NOT** see _udrc_ enumerated  **do NOT continue**
  * Until the UDRC/DRAWS drivers are loaded the configuration scripts will not succeed.
  * Run the ```showudrc.sh``` script and [post the console output to the UDRC groups.io forum](https://nw-digital-radio.groups.io/g/udrc/topics)

#### Initial Image Config

* If you are running with an attached monitor you should see the Raspbian 'Welcome to Raspberry Pi' piwiz splash screen
  * **DO NOT** run the piwiz splash screen yet


##### Update NWDR image configuration scripts
```
cd
cd n7nix
git pull
cd config
./bin_refresh.sh
```

#### Update Raspberry Pi OS package information and their dependencies

```
sudo su
apt-get update
apt-get upgrade

# revert back to normal user
exit
```

* If you are running with an attached monitor you should see the Raspbian 'Welcome to Raspberry Pi' piwiz splash screen
  * Follow the screens as you would on any other Raspbian install.
  * When prompted to restart the RPi please do so.

### 2. Second boot

##### Configure core functionality

* Whether you want **direwolf for packet functionality** or run **HF
apps** with the draws HAT do the following:

```bash
cd
cd n7nix/config
# Become root
sudo su
./app_config.sh core
```

* The above script sets up the following:
  * iptables
  * RPi login password
  * RPi host name
  * mail host name
  * time zone
  * current time via chrony
  * AX.25
  * direwolf
  * systemd

### 3. Third boot

* **You must set your ALSA configuration** for your particular radio at this time
  * Also note which connector you are using as you can vary ALSA settings based on which channel you are using
    * On a DRAWS hat left connector is left channel
    * On a UDRC II hat mDin6 connector is right channel
  * You also must route the AFOUT, compensated receive signal or the DISC, discriminator  receive signal with ALSA settings.
  * Verify your ALSA settings by running ```alsa-show.sh```

*  [verify your installation is working properly](https://github.com/nwdigitalradio/n7nix/blob/master/docs/VERIFY_CONFIG.md)

* **NOTE:** the default core config leaves AX.25 & _direwolf_ **NOT running** & **NOT enabled**
  * The default config is to run HF applications like js8call, wsjtx
  and FLdigi
  * If you are **not** interested in packet and want to run an HF app then go ahead & do that now.

### 4. For Packet Turn on Direwolf & AX.25

  * If you want to run a **packet application** or run some tests on the
    DRAWS board that requires _direwolf_ then enable AX.25/direwolf like this:

  * enable packet ax25/direwolf
```
# Not required to be root
ax25-start
```
