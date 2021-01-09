## Chattervox for the Raspberry Pi

An AX.25 packet radio chat protocol with support for digital signatures and binary compression. Like [IRC](https://en.wikipedia.org/wiki/Internet_Relay_Chat) over radio waves.

### Brannon Doresey's Chattervox Documentation

* [Chattervox README](https://github.com/brannondorsey/chattervox/blob/master/README.md)
* [Chattervox examples](https://github.com/brannondorsey/chattervox-examples/blob/master/README.md)

### How to install Chattervox on a Raspberry Pi

* First clone or refresh the NWDR N7NIX repository
  * Comes with the NWDR image

```
# Refresh the N7NIX repository
cd
cd n7nix
git pull

# Do the chattervox install
cd keyb2keyb
./cv_install.sh
```

##### The _cv_install.sh_ install script does the following:

* Detects if there is a current version of chattervox installed and removes it
* Detects if chattervox is running & stops it
* Clones Brannon Doresey's (KC3LZO) Chattervox [github repository](https://github.com/brannondorsey/chattervox)
* Downloads required dependencies
* Transpiles any [TypeScript](https://en.wikipedia.org/wiki/TypeScript) (ts) files
* Displays any previously generated key pairs
* Does an initial configuration of chattervox if required.
* Updates the chattervox start script in the local BIN directory.

###### Initial configuration questions from chattervox

```
Welcome! It looks like you are using chattervox for the first time.
We'll ask you some questions to create an initial settings configuration.


What is your call sign (default: N0CALL)? N7NIX
What SSID would you like to associate with this station (press ENTER to skip)? 4
Do you have a dedicated hardware TNC that you would like to use instead of Direwolf (default: no)? no
Would you like to connect to Direwolf over serial instead of the default TCP connection (default: no)? no
{
  "version": 3,
  "callsign": "N7NIX",
  "ssid": 4,
  "keystoreFile": "/home/gunn/.chattervox/keystore.json",
  "kissPort": "kiss://localhost:8001",
  "kissBaud": 9600,
  "feedbackDebounce": 20000
}
Is this correct [Y/n]? y
```



### How to Run Chattervox

* Since Chattervox for the Raspberry Pi was built from source you need to use a script (_chattervox.sh_) to wrap the actual chattervox program.

* First add my public key
```
chattervox.sh addkey N7NIX 04c4ba4bd163be7a0468731593ad887897adcd6e5d7da2f7f7965fb2ba2add119758522731403f1a96119ceffd2c8b6b41

# Verify
chattervox.sh showkey
```

* Open a chat room
```
chattervox.sh chat
```

* Send me a message on NET-16
* Email me your public key.
  * You can locate your public key by running _chattervox.sh showkey_

### Other chattervox commands

* See [Usage](https://github.com/brannondorsey/chattervox#usage) from the chattervox README
* As mentioned before all the chattervox command are started from a script because this project was built from source

```
# send a packet from the command-line
chattervox.sh send "this is a chattervox packet sent from the command-line."

# receive *all* packets and print them to stdout
chattervox.sh receive --allow-all

# generate a new public/private key pair, and use it as your default signing key
chattervox.sh genkey --make-signing

# remove a friend's public key if it has become compromised
chattervox.sh removekey KC3LZO 0489a1d94d700d6e45508d12a4eb9be93386b5b30feb2b4aa07836398781e3d444e04b54a6e01cf752e54ef423770c00a6

# print all keys in your keyring
chattervox.sh showkey
```

### chatterbox bugs and work arounds
* If you get __(KEY NOT FOUND)__ message during your chat
  * Edit keystore.json in directory ~/.chattervox and pad all call signs to 6 characters with spaces.
  * See [issue #28](https://github.com/brannondorsey/chattervox/issues/28)
