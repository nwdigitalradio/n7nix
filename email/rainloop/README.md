## Rainloop

##### DRAWS image
* If you are using a DRAWS image then the Rainloop source has already been installed.
* Run Rainloop app from a browser for initial configuration, see instructions below.

##### Manual install
* Rainloop is installed from a script _rainloop_install.sh_
  * It gets the latest source from ```https://www.rainloop.net/repository/webmail/rainloop-community-latest.zip```
    * Sets permissions
    * Sets app ownership

### Configuration
* Using a browser start Rainloop in Admin mode using this URL ```localhost/?admin```
  * You can also use another computer on the same network & substitute localhost with the ip address of your RPi.

##### Set new admin password
* Screen displays _Login_ and _Password_
* Login using the initial default login of _admin_ with a password of _12345_
* Should see a warning: __You are using the default admin password.__
  * The next line will contain a link to change your admin password, click that link and change your password __ONLY__
  * Click __Update Password__

#### Domains
* Using left panel click on Domains
* Click Add Domain
* Name: localhost

#### Edit Domain "localhost"

* IMAP Server: localhost
* IMAP Port: 143
* IMAP Secure: None
* IMAP Server: click _use short login_
* SMTP Server: localhost
* SMTP Port: 25
* SMTP Secure: None
* __DO NOT DO THIS__: SMTP click green check mark next to _Use authentication_
  * Make sure green mark next to _Use authentication_ is unchecked.
* Click +Add in right hand corner

#### Login
* Using left panel click on Login
* Default domain: localhost

#### Admin Panel complete, Login in to new account
* Change Browser url to ```localhost```

* Login using Email: pi@localhost, password: user pi password

#### Add an identity
* In right hand area of web page left click on arrow by person's head next to pi@localhost
* Click on Settings
* Using left panel click on _Accounts_
* Under Identities, click on _Add an Identity_
* Email: <your_call_sign>@winlink.org
* Name: <your_full_name> ie. Joe Blow
* Click on _Reply-To_ and set to <your_call_sign>@winlink.org
* Click _Add_ in lower right hand corner
* In the Identites list at the bottom click on the six dots between the head & your name & drag above pi@localhost
  * This is now the default identity.

#### Select Default text editor

* Using left pannel click on _General_
* Using the drop down menu for _Default text editor_ select _Plain (forced)_
* Click _Back_ on top left to go to default mail screen

#### Send Test

* Compose a message by clicking at top left on _New_
* To: <your_callsign>@winlink.org
* Subject: <fill_this_in>
* Hit tab 3 times & verify cursor is in email body
* _Debug_: In a console on the RPi type: ```tail -f /var/log/mail.log```
* Click on _Send_ button at top left

#### Use paclink-unix
* In another browser window set url to ```localhost:8082```
  * You can also use another computer on the same network & substitute localhost with the ip address of your RPi.
* Click on _Outbox_ to get a count of number of files in the wl2k outbox
* Click on _Telnet_ or _AX.25_
* Click on _Telnet_ again and in the Rainloop browser tab _Reload Message List_ icon, circle in menu bar
  * verify that the email previously sent now appears in the Rainloop _Inbox_

#### Debug

* Monitor rainloop log in a console
```
~n7nix/email/rainloop/rl_log.sh
```

* Monitor mail log in a console
```
tail -f /var/log/mail.log
```
