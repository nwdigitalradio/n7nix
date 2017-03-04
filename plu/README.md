# Test Mail client

## Test PLU web interface

### Testing webapp

#### Install node.js & required modules
* nodejs & the required modules are installed with the _plu/pluimap_install.sh_ script
  * To see what gets installed

### Test webapp

* nodejs should be started manually like this:
```
su
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

