# paclink-unix has 2 install options

## [basic](PACLINK-UNIX_INSTALL.md)
* Enables mail clients that support Unix movemail.
  * Thunderbird & [mutt](http://www.mutt.org/) or an upstream version of mutt called [NeoMutt](https://www.neomutt.org/)

## [with imap server](PACLINK-UNIX-IMAP_INSTALL.md)
* Enables IMAP mail clients over WiFi
  * I use [K-9 Mail](https://k9mail.github.io/) on my Android mobil device

# How to Test Mail client
###### Sending mail is a two step process
* Compose an e-mail with your e-mail app
* Send the e-mail with paclink-unix with a web interface

###### Receiving mail is a two step process
* Get e-mail using paclink-unix
* Reading an e-mail with your e-mail app

## Test PLU web interface

### Testing webapp

#### Install node.js & required modules
* nodejs & the required modules are installed with the _plu/pluimap_install.sh_ script

### Test webapp

* nodejs should be started manually like this:
```
sudo su
cd /usr/local/src/paclink-unix/webapp
nodejs plu-server.js
```

* This will take over the console & outputs a verbose amount of debug statements from the node.js app, _plu-server.js_
* Now open a browser & go to: __your_ip_address__:8082
* Should see something like the following:

---

![plu](images/pluwebcapture.png)

---

# Configure a mail client

## [mutt or Neomutt e-mail client](https://www.neomutt.org/)
* mutt is configured by default in the  [mutt install script](https://github.com/nwdigitalradio/n7nix/blob/master/plu/mutt_install.sh)
  * mutt is installed by default when paclink-unix is installed.

## [K-9 Mail Android client](https://k9mail.github.io/)
* Reference configuration for K-9 Mail

### Fetching mail

#### Incoming server

* IMAP server: 10.0.42.99
* Security: SSL/TLS
* Port: 993
* Username: <login_user_name>
* Authentication: Normal password
* Password: <login_password>

### Sending mail

#### Outgoing server

* SMTP server: 10.0.42.99
* Security: SSL/TLS
* Port: 465
* Require sign-in: check mark
* Username: <login_user_name>
* Authentication: Normal password
* Password: <login_password>

