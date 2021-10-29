# Steps to verify packet transmission & reception

**NOTE:** When the Linux AX.25 stack is used from start-up, like after a cold or warm
boot, the first 2 packets sent are parsed as control packets and are not
transmitted.

This is only seen at AX.25 start-up.

You can mitigate that by using the _beacmin.sh_ or _btest.sh_ scripts twice
before starting to test anything.

## Verify Transmit

#### Use beacon on APRS frequency
  Use the [_btest.sh_ or _beacmin.sh_ scripts](https://github.com/nwdigitalradio/n7nix/tree/master/debug#5-direwolfudrc-testing) with your radio tuned to the
  APRS 2M frequency.  Verify the beacon packets were gated to the
  Internet on aprs.fi.

#### Use another radio to listen to what is being transmitted
  Use a handy talky to listen for your packets being transmitted.  If
  you do NOT see your packets gated on aprs.fi OR hear them on your
  handy talky then use the [_measure_deviate.sh_ script](https://github.com/nwdigitalradio/n7nix/tree/master/deviation) to
  output a tone. Listen for it on your handy talky. This will verify PTT
  and your cable from the DRAWS hat to your radio. It also gives you a
  way to measure your deviation settings.

## Verify you are receiving packets:

#### Use a packet spy to look at received packets
  Tune your radio to the 2M APRS frequency because it should be fairly
  active, 144.390

  start up a packet spy in a console
  sudo su
  listen -a

#### Use direwolf log file
  Check output from direwolf log file:
  tail -f /var/log/direwolf/direwolf.log

## Verify ALSA settings
  Verify that you have the correct ALSA settings for the radio you are
  using:

```
alsa-show.sh
```

## Verify Packet Connected Mode
  Once you have verified that you are in fact transmitting and receiving
  valid packets use a Winlink app to do a point-to-point connection with
  someone to verify connected mode.


