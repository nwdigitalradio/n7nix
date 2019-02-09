## Verify Winlink Functionality
#### Mutt

* Mutt is a small but very powerful __text__ based mail client
* By default the mutt email client is installed & configured
* To learn more about mutt go [here](http://www.mutt.org/)
* mutt is used to verify your postfix/paclink-unix setup using the [n7nix/debug/chk_mail.sh script](https://github.com/nwdigitalradio/n7nix/blob/master/debug/chk_mail.sh)

#### Claws-mail

* Follow [these
instructions](https://github.com/nwdigitalradio/n7nix/blob/master/email/claws/README.md)
when running claws-mail for the first time
* claws-mail should have a desktop icon or can be accessed from Main Menu > Internet > Claws Mail

### How to verify paclink-unix install - telnet

* Open claws-mail
* Compose an email & address it to both:
  * <your_callsign>@winlink.org
  * <your_regular_email_address>
* Be sure to fill in the Subject line
* Click __Send__

* You should now have a file waiting to be sent via Winlink in your Winlink outbox
  * Verify by running _chk_perm.sh_
  * Last line should read "1 files in outbox"

* Now send the message by running _wl2ktelnet_ in a console.
* Run _check_perm.sh_ again
* Last line should read "No files in outbox"

* Run _wl2ktelnet_ again & look in your claws-mail __INBOX__
  * You should find the email you just sent
* Look in your regular email __INBOX__ you should find the same email.

### How to verify paclink-unix install - AX.25

##### Find a nearby RMS Gateway

* Run the rmslist.sh script to get a list of RMS Gateway callsigns, frequencies & distances
  * Run it like this with first number as an integer, second is your grid square

```
rmslist.sh 40 CM96BX
Proximity file is: 0 hours 8 minute(s), 14 seconds old
Using distance of 40 miles & grid square CM96BX

  Callsign       Frequency  Distance    Baud
 K6BJ-11   	 145710000	5	9600
 W6TUW-10  	 144910000	5	1200
 K6BJ-10   	 145010000	10	1200
 KE6AFE-10 	 145630000	10	1200
 WB6RJH-10 	 145690000	14	1200
 KF6GPE-10 	 145630000	20	1200
 K2RDX     	  14107500	24	 600
 K2RDX-10  	 145630000	24	1200
 WA6LIE-10 	 145690000	24	1200
```

##### Run wl2kax25

```
wl2kax25 -c w6tuw-10
```

* Run _man wl2kax25_ for more information.