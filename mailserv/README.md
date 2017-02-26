# How to test a dovecot mail server

* [Dovecot Test Installation](http://wiki.dovecot.org/TestInstallation) from dovecot wiki

### Check that dovecot is running

```
systemctl status dovecot
```
*  Should see 'active (running)' in the output

### Check that dovecot is listening
* As root
```
telnet localhost 143
```
* for a graceful exit type:
```
e logout
```

## local ssl connection

```
openssl s_client -connect localhost:993
```

* This opens a connection to the IMAP server software via SSL.
  * 993 is the numbered port devoted to secure IMAP traffic.)
  * You should see a long series of certificate-verifying jargon as SSL does its thing.
  * Finally, Dovecot will say:

```
OK Dovecot ready.
```
* Now type

```
a CAPABILITY
```

* to ask Dovecot what it is capable of.
* This is how IMAP clients say hello. Dovecot will respond with something like:


```
CAPABILITY IMAP4rev1 SASL-IR SORT THREAD=REFERENCES MULTIAPPEND UNSELECT LITERAL+ IDLE CHILDREN NAMESPACE LOGIN-REFERRALS STARTTLS AUTH=PLAIN
OK Capability completed.
```

* IMAP server is now capable. End the connection by typing:

```
e LOGOUT
```
```
connect: Connection refused
connect:errno=111
```
```
postconf | grep -e '^mydomain' -e '^myhostname' -e '^myorigin'
```

* As user ie. not root
```
mutt -f imap://pi@localhost
```
* Get this, need to fix:
```
 WARNING: Server hostname does not match certificate
```

```
postconf | grep -e '^mydomain' -e '^myhostname' -e '^myorigin'
```
### Check that Dovecot is allowing logins
## Using telnet to verify login
* Port 143 is default IMAP non-encrypted port

```
telnet localhost 143
Trying ::1...
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
* OK [CAPABILITY IMAP4rev1 LITERAL+ SASL-IR LOGIN-REFERRALS ID ENABLE IDLE STARTTLS AUTH=PLAIN AUTH=LOGIN] Dovecot ready.
a login <user> <password>
a OK [CAPABILITY IMAP4rev1 LITERAL+ SASL-IR LOGIN-REFERRALS ID ENABLE IDLE SORT SORT=DISPLAY THREAD=REFERENCES THREAD=REFS THREAD=ORDEREDSUBJECT MULTIAPPEND URL-PARTIAL CATENATE UNSELECT CHILDREN NAMESPACE UIDPLUS LIST-EXTENDED I18NLEVEL=1 CONDSTORE QRESYNC ESEARCH ESORT SEARCHRES WITHIN CONTEXT=SEARCH LIST-STATUS SPECIAL-USE BINARY MOVE] Logged in
b select inbox
* FLAGS (\Answered \Flagged \Deleted \Seen \Draft)
* OK [PERMANENTFLAGS (\Answered \Flagged \Deleted \Seen \Draft \*)] Flags permitted.
* 1 EXISTS
* 1 RECENT
* OK [UIDVALIDITY 1473875571] UIDs valid
* OK [UIDNEXT 9] Predicted next UID
* OK [HIGHESTMODSEQ 11] Highest
b OK [READ-WRITE] Select completed (0.013 secs).
c list "" *
* LIST (\HasNoChildren \Sent) "." Sent
* LIST (\HasNoChildren) "." INBOX
c OK List completed.
e logout
* BYE Logging out
e OK Logout completed
```

* Port 993 is default IMAP encrypted port
```
openssl s_client -connect localhost:993
```

