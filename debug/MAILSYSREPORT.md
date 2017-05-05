# Sending System reports via Winlink using CRON

 The following 3 scripts are used:

* wl2klog_genmail.sh
  * Generate the report to be sent in the body of the email
* wl2klog_sendmail.sh
  * Use command line mutt & paclink-unix to send a Winlink message.
* wl2k_outboxchk.sh
  * Periodically check the paclink-unix outbox for any messages to be sent.

##### Config Destination Email Recepients
* A daily mail message will be sent to which ever email address SENDTO in wl2klog_sendmail.sh is set to.
  * If the SENDTO variable is left as _N0ONE_ then the script will get a CALLSIGN from the direwolf config file & send it to `<callsign>`@winlink.org
  * To send the report to a different call sign or more than one call sign just enter the call sign(s) on the SENDTO line in wl2klog_sendmail.sh
  * If you want to address the mail report to something other than a winlink address than a full address is required.
* For example:
```
SENDTO="n7nix kf7fit some_guy@bogusisp.com"
```

##### Config which transport to use

The _wl2klog_sendmail.sh_ script currently defaults to using telnet as
the transport. This is convenient for testing but you will probably
want to change that to using your radio & connecting to an RMS Gateway.
Modify the __wl2ktranSport=__ line to set the transport you want to use.

* The _-s_ option is used to specify transmit only, do not pick up any messages
* The _-c_ option specifies the destination RMS Gateway callsign

###### Telnet
```
"/usr/local/bin/wl2ktelnet -s"
```

###### Radio via RMS Gateway
```
"/usr/local/bin/wl2kax25 -s -c <some_rms_gateway_callsign>"
```

##### Config crontab

* Required entries in crontab
  * On a daily basis send a report via Winlink email just before midnight
  * On a 10 minute interval check for any email waiting to be sent in the outbox

```
10 *  * * * /home/pi/bin/outboxchk.sh
59 23 * * * /home/pi/bin/daily_sendmail.sh
```

* Modify the local crontab:
```
crontab -e
```
* Verify the local crontab:
```
crontab -l
```


* Using -s option (send only) with any of the wl2k transport commands (wl2kax25, wl2ktelnet, wl2kserial) produces an artifact since it abruptly stops the Winlink session.
  * This will only occur if there are messages that are available to be picked up from a CMS.

```
wl2ktelnet: <*** [1] [01100-006] - Unexpected response to proposal - Disconnecting (207.32.162.17)
wl2ktelnet: unrecognized command (len 85): /*** [1] [01100-006] - Unexpected response to proposal - Disconnecting (207.32.162.17)/
```

### Report generator

* The report generator script _wl2klog_genmail.sh_ displays the following:

  * uptime
  * disk usage
  * Logged-in info
  * Users running processes
  * Status of AX.25 device service
  * Status of Direwolf service
