# Installing VNC with systemd startup

## What's VNC

"there are occasions where accessing the gui is nice"

Virtual Network Computing (VNC) is a graphical desktop sharing system
that uses the Remote Frame Buffer protocol (RFB) to remotely control
another computer. Check [wikipedia]
(https://en.wikipedia.org/wiki/Virtual_Network_Computing) for more
info.  There are 67 vnc programs listed in [Comparison of remote
desktop
software](https://en.wikipedia.org/wiki/Comparison_of_remote_desktop_software)
so you have choices.  One of the choices is x11vnc recommend by Ken
Koster N7IBP. Ken supplied this [systemd
service](https://github.com/nwdigitalradio/n7nix/blob/master/vnc/vnc.service)
file & these setup notes which will start x11vnc during boot.


## Install & systemd service file setup

Users will need to install x11vnc since it's not installed automatically

```bash
sudo apt-get install x11vnc
```

Copy the service file
[vnc.service](https://github.com/nwdigitalradio/n7nix/blob/master/vnc/vnc.service)
to /lib/systemd/system then enable with

```bash
sudo systemctl enable vnc.service
````
and start with

```
sudo systemctl start vnc
```

From then on it will start after every boot.

If you need to temporarily stop it use:

```bash
sudo systemctl stop vnc
```

and to disable *start on boot* do
```
sudo systemctl disable vnc
```

Any vnc compatible client should work, and if your client supports avahi/
zeroconf it should have a search function that lists all the vnc machines on
your local network.  (I use gnome vinagre)

