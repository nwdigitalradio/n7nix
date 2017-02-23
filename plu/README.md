# Test Mail client

## Test PLU web interface

### Testing webapp

#### Install node.js & required modules
```
su
apt-get install nodejs npm
npm install -g websocket connect finalhandler serve-static

cd /usr/local/src/webapp
#wget https://code.jquery.com/jquery-3.1.1.min.js
#cp jquery-3.1.1.min.js jquery.js
npm install jquery
```


### Test webapp

* nodejs should be running
```
su
cd /usr/local/src/webapp
nodejs plu-server.js
```

* open a browser & go to: __your_ip_address__:8082
* Should see something like this:

---

![plu](images/pluwebcapture.png)

---

# Configure a mail client

## [mutt or Neomutt e-mail client](https://www.neomutt.org/)
* mutt is configured by default in the  [mutt install script](https://github.com/nwdigitalradio/n7nix/blob/master/plu/mutt_install.sh)
  * mutt is installed by default when paclink-unix is installed.

## [K9 Android email client](https://k9mail.github.io/)

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

