## Claws-mail

##### DRAWS image
* If you are using a DRAWS image then claws-mail has already been installed.
* Run claws-mail app for initial configuration, see instructions below.

##### Manual install
* Claws-mail is installed from a Debian package
* Install script, _claws_install.sh_, is first run to install package
  * Install script should be run as user that will be using claws-mail
* Next run claws-mail as a GUI app. & follow configuration steps below.


### Configuration

#### First screen

* Your name: your_real_name (ie. Joe Blow)

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


#### Second screen: Receiving mail

* Server type: IMAP
* Server address: localhost
* Username: <your_login_name>
  * This is the name you are logged in as on your RPi ie. your user name is probably pi
* Password: <your_login_password>
  * This is the password you use for the above username to log in to your RPi
* imap server directory:
  * leave this entry blank

#### Third screen: Sending mail

* SMTP server address: localhost

#### Fourth screen: Configuration Finished

* Click save to start

#### Verify claws-mail
* Click on INBOX in left panel
  * Any emails from root during install?
* If imap mail directory already exists click **getmail** (left most icon in claws-mail) to see any previous email.

* You may have to run _Rebuild folder tree_ when you first start up
  * Right click on the top folder name (probably pi@localhost) & choose _Rebuild folder tree_
  * You should only have to do this once
* __Note:__ you will also receive any mail the system sents to user root.
* Compose an email to <user>@localhost ie. (pi@localhost)
  * Click on _Getmail_, the email should appear in your __INBOX__
