## Basic Support Techniques for Raspberry Pi

For debugging problems that you expect to get help on please cut &
paste text from a console window into your email. Not html, not jpeg
images, not an mp4 movie or a youtube link, __text only__.

Below is a list of assumptions about solving problems & getting a
DRAWS hat humming along.

#### Assumption 1: RPi & another computer
* You have an RPi with the DRAWS hat installed, connected to your home network.
* You have a computer that has email & browser capability.

#### Assumption 2: ssh
* You have a program on your computer that can be an SSH client or serial console.
  * For Windows guys that usually means downloading PuTTY
    * [PuTTY home page](https://www.putty.org/)
    * [Connect to Linux from Windows by using PuTTY](https://support.rackspace.com/how-to/connecting-to-linux-from-windows-by-using-putty/) from RackSpace Support.
    * [Search the udrc forum for PuTTY](https://nw-digital-radio.groups.io/g/udrc/search?q=putty)
  * For everyone else (Linux/Unix/MAC) you already have a program that does this called _ssh_.
* __Learn how to _ssh_ into your RPi__

##### Virtual Network Computing: VNC

* Besides using _ssh_ to transfer console output to your email program you may also use VNC
  * I do not use VNC because _ssh_ provides everything that I need to configure & run an RPi.
  * If you feel more comfortable using a GUI then you might find a VNC setup useful.
* Ken Koster N7IBP has provided instructions on installing VNC on a Raspberry Pi [here](https://github.com/nwdigitalradio/n7nix/tree/master/vnc)
* __Note:__ By default the provided NWDR image has realvnc-vnc-server installed

#### Assumption 3: cut & paste
* Learn how to cut & paste text from a ssh console window to an email app.

#### Assumption 4: __use the NWDR image__
* Load the RPi image from NW Digital Radio found [here](http://nwdig.net/downloads/)
  * current_image.zip and nwdrxx.zip __ARE__ the same file.
  * A lot of work went into installing software on the NWDR image and that is what is supported.
  * I will not support your effort to install software starting from a Raspbian image.

After successfully following the instructions
[here](https://nw-digital-radio.groups.io/g/udrc/wiki/DRAWS%3A-Getting-Started)
to create a working RPi image that supports the core functionality of a
UDRC/DRAWS hat you should follow these hints to get further help.

* When you post a problem that you want help on besides describing the
problem in as much detail as possible, run the _showudrc.sh_ command
on your RPi & cut & paste that console output into an email or post to
udrc@nw-digital-radio.groups.io

* Learn how to search the [groups.io udrc forum](https://nw-digital-radio.groups.io/g/udrc/topics)
  * The search button on groups.io forums actually works.

* Learn how to google. Google is your friend.