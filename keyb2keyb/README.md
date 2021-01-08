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

* Detects if there is a current version of chatterbox installed and removes it
* Detects if chattervox is running & stops it
* Clones Brannon Doresey's (KC3LZO) Chattervox [github repository](https://github.com/brannondorsey/chattervox)
* Downloads required dependencies
* Transpiles any [TypeScript](https://en.wikipedia.org/wiki/TypeScript) (ts) files
* Displays any previously generated key pairs
* Does an initial configuration of chattervox if required.
* Updates the chattervox start script in the local BIN directory.


### How to Run Chattervox

* Since Chattervox for the Raspberry Pi was built from source you need to use a script to wrap the actual chatterbox program.

* First add my public key
```
chattervox.sh addkey N7NIX 04c4ba4bd163be7a0468731593ad887897adcd6e5d7da2f7f7965fb2ba2add119758522731403f1a96119ceffd2c8b6b41
```

* Open a chat room
```
chattervox.sh chat
```

* Send me a message on NET-16
* Email me your public key.

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