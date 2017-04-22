## Alpine mailer

#### Getting the source for compiling on Unix/Linux
* SourceForge has version 2.03 **- DO NOT USE**
  * https://sourceforge.net/projects/re-alpine/
* Latest source (2.21.1 4/22/2017) in a git repo is here
  * git clone git://repo.or.cz/alpine.git

#### Getting a package

* Debian Jessie has an alpine package 2.11

#### Building from source on RPi 3


```
git clone git://repo.or.cz/alpine.git
cd alpine/
./configure
make -j2
sudo su
make install
# Display version
alpine -v
```
* During make got the following error
```
security/pam_appl.h: No such file or directory
```
* Need the pam dev library

```
apt-get install libpam0g-dev
```
##### Configuration

* Started from a mutt configuration that worked.

###### Sending winlink msgs

* Need to set the following in .pinerc
  * You can set any of these from the SETUP menu
  * I found it easier to just edit the .pinerc file

```
personal-name=
user-domain=winlink.org
customized-hdrs=From: n7nix,
        Reply-To: N7NIX@winlink.org,
        Mbo:N7NIX
````

###### Receiving winlink msgs

  * Postfix is currently setup to use Maildir format mailboxes

  * alpine by default does not support Maildir format mailboxes
    * There is a patch http://patches.freeiz.com/alpine/info/maildir.html
    * Patch only works for these versions
      * 1.00, 1.10
      * 2.00, 2.01, 2.10, 2.11, 2.20, 2.21
