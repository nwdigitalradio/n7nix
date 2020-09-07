# How To:
## Use Winlink On A Raspberry Pi With A Draws Hat Using Packet Radio

This guide ssumes you are using an NWDR image so you do __NOT__ need to install
anything __BUT__ you do need to configure a number of things.

First read the notes from the [Start the Config Script link](https://github.com/nwdigitalradio/n7nix/blob/master/plu/PACLINK-UNIX_INSTALL.md#start-the-config-script)

* The NWDR image has AX.25, direwolf, paclink-unix and 3 email clients all ready installed but not configured.
* Focus of this configuration will be on 1200 baud packet radio connecting to a Winlink RMS Gateway or P-2-P between 2 Winlink stations.

Before configuring paclink-unix, verify ax.25/direwolf is operating.
Please read __ALL__ of the following two guides:

* [Getting Started Guide](https://nw-digital-radio.groups.io/g/udrc/wiki/8921)

* [Verifying CORE Install/Config on UDRC/DRAWS](https://github.com/nwdigitalradio/n7nix/blob/master/docs/VERIFY_CONFIG.md)

I recommend having a console window open & running a packet spy like this:
```
sudo su
listen -a
```
##### Once paclink-unix is Configured #####
* install either _claws-mail_ or _rainloop_ email clients.
  *  Really you will want to install both of them to see which one you like best.
  * Generally speaking you can run any Linux email client I just happen to be most familiar with _mutt_, _claws-mail_ & _rainloop_ email
clients.
  *  paclink-unix configuration automatically installs email client _mutt_ in order to verify the other email utilities are working.

###### To run verification script _chk_mail.sh_:
```
cd
cd n7nix/debug
./chk_mail.sh
```
The chk_mail.sh script uses _mutt_ to send me two Winlink messages that will
facilitate verifying your Winlink configuration.

The _claws-mail_ & _rainloop_ email clients require following their
configuration guides __exactly__.

* [Claws-mail email client config](https://github.com/nwdigitalradio/n7nix/blob/master/email/claws/README.md#configuration)
* [Rainloop email client config](https://github.com/nwdigitalradio/n7nix/blob/master/email/rainloop/README.md#configuration)


If you take it step by step Winlink configuration on an RPi is not as
complicated as it seems.

##### Note
* Running _claws-mail_ assumes an attached monitor & keyboard to your RPi.
* _rainloop_ runs in a web browser for both the email client & paclink-unix
  *  This means you can run them locally or from an other computer in a browser on the same subnet.
