## Scripts

### bbs_install.sh
* Install the latest version of linBBS from SourceForge

### bbs_verchk.sh
* Verify version numbers of code in SourceForge, local source & installed linFBBS

### checkbbs.sh
* Read index of contents & compare with local copy
* Download any new contents

### updatebbs.sh
* Upload a bulletin or private message to bbs

## After Install How to run linFBB

In a console: __must run as root__

```
 /usr/local/share/doc/fbb/fbb.sh start
```

* Want to access directory /usr/local/var/ax25/fbb but my files were installed to /var/ax25/fbb
  * symlink
```
ls -salt /var/ax25
0 lrwxrwxrwx 1 root root 19 Sep 19  2019 /var/ax25 -> /usr/local/var/ax25
```

* Run as root:
```
sudo su
/usr/local/share/doc/fbb/fbb.sh start
```
```
Files set-up complete
FORWARD set-up
BBS set-up
Set-up complete
GMT 18:11 - LOCAL 11:11
Starting multitasking ... ok

FBB options : -s
Running XFBB in background mode ^C to abort
Starting XFBB (pwd = /usr/local/var/ax25/fbb)...
 start Done
```
