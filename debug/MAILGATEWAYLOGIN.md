# RMS Gateway Login report via SMTP or Winlink using CRON

 The following scripts are used:

* gwcron.sh
  * Generate a text file containing count of Logins & Logouts
* gwcrondaily_smtp.sh
  * Send above text file via regular email.
  * Requires a properly configured email MTA
  * Edit gwcrondaily_smtp.sh script SENDTO variable
* gwcrondaily_wl2k.sh
  * Send above text file via Winlink email.
  * Edit gwcrondaily_wl2k.sh script CALLSIGN variable

For reference there is also a document which describes
[sending a System report via Winlink](https://github.com/nwdigitalradio/n7nix/blob/master/debug/MAILSYSREPORT.md)

##### Config crontab

* Required entries in users crontab
  * Example crontab on a daily basis sends an email RMS Gateway report at 1AM

```
0 1 * * * /home/gunn/bin/gwcrondaily_smtp.sh
```

### Report generator

* The report generator script _gwcron.sh_ displays the following:

  * Number of gateway logins
  * Number of gateway logouts
  * If there are gateway logins will list callsigns that logged in.
  * System uptime
  * disk usage
