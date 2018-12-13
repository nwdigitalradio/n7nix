If you want direwolf functionality with the draws hat do this:

cd
cd n7nix/config
sudo su
./app_config.sh core

This will run a script that sets up AX.25, direwolf & systemd

Now reboot your RPi & confirm your installation is working:

Receive
Tune your radio to the 1200 baud APRS frequency: 144.39 because there
should be lots of traffic there.

tail -f /var/log/direwolf/direwolf.log
or
become root & run listen -at in a console window

Transmit
Tune your radio to the 1200 baud APRS frequency: 144.39
cd
cd n7nix/debug
sudo su
./btest.sh -P [udr0|udr1]
This will send either a position beacon or a message beacon
with the -p or -m options.

Using a browser go to: https://aprs.fi/
Under Other Views, click on raw packets
Put your call sign followed by an asterisk in "Originating callsign"
Click search, you should see the beacon you just transmitted.

After that you can configure rmsgw, paclink-unix or someother packet
program that requires direwolf ie.:

./app_config.sh rmsgw
./app_config.sh plu

If you want to run some other program that does NOT use direwolf then do
this:
cd
cd bin
sudo su
./ax25-stop
This will bring down direwolf & all the ax.25 services.
