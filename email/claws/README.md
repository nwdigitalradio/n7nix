## Claws-mail

* Claws-mail is installed from a Debian package

* Install script, _claws_install.sh_, is first run to install package
* Next run claws-mail as a GUI app. & follow configuration steps below.
* Finally run configuration script again to verify config

* Install script should be run as user that will be using claws-mail


#### Configuration

##### First screen

* Your name: your_real_name (Joe Blow)

###### winlink email

* For a dedicated winlink email client set your _email address_ like this:

```
<your_callsign>@winlink.org
```

###### regular email
* If you are configuring claws-mail just as a local email client then set your _email address_ like this:

```
<your_user_name>@<your_host_name>.localnet
```


##### Second screen: Receiving mail

* Server type: IMAP
* Server address: localhost
* Username: <your_login_name>
* Password: <your_login_password>
* imap server directory: ?

##### Third screen: Sending mail

* SMTP server address: localhost

##### Fourth screen: Configuration Finished

* Click save to start
* If imap mail directory already exists click **getmail** (left most icon in claws-mail) to see previous email.