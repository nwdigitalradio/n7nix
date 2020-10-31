# Methods Tried
* Without success

#### Use program to generate wav file to pass to radio sound card.

* Found a python program on github that supports numbers, ABCD and '*'
  * [cleversonahum / dtmf-generator](https://github.com/cleversonahum/dtmf-generator/blob/main/dtmf-generator.py)

* To install

```
git clone https://github.com/cleversonahum/dtmf-generator
python3.7 -m pip install scipy
python3.7 -m pip install -U matplotlib

```
* This program would not run without modifying.
  * Reference: [.wav file doesn't play any sounds](https://stackoverflow.com/questions/10558377/wav-file-doesnt-play-any-sounds)
  * Initially got this error
```
 aplay test.wav
aplay: test_wavefile:1130:  can't play WAVE-files with sample 64 bits wide
```
* __Had to modify this line__
```
        wav.write(args.output, args.samplefrequency, dtmf.signal)
```
* to this
```
       wav.write(args.output, args.samplefrequency, dtmf.signal.astype(np.dtype('i2')))
```

* To run
```
python3.7 dtmf-generator.py -p BA236288*A6B76B4C9B7# -f 20000 -t 0.08 -s 0.08 -o test.wav -a 90 -d
```

###### Command line arguments for dtmf-generator.py

* -p
  * phone number, actually digits of any DTMF string to send
* -f
  * Sample frequency
* -t
  * tone duration
* -s
  * Silence duration between consequtive tones
* -a
  * Output tone amplitude
* -o
  * Name of wav file to generate
* -d
  * Set debug flag, enable FFT graph of each tone


#### Use program gen to generate wav file
* [gen-ng reference](https://github.com/EliasOenal/multimon-ng/blob/master/gen.c)
* Should promise **but needs ALOT of work**

* Found this from KB9mwr which uses SoX:
[Two-Tone Pager Decoder Using Multimon](https://www.qsl.net/kb9mwr/projects/pager/Two-Tone%20Pager%20Decoding%20Using%20Multimon.pdf)

* [Link to mutimon-ng github page](https://github.com/EliasOenal/multimon-ng)
* multimon-ng can be built using either qmake or CMake:
```
mkdir build
cd build
cmake ..
make
sudo make install
```
* create audio files that contain the key press tones in the sequence entered. Example follows:
```
gen -t wav -d 123A456B789C*0#D
gen -t wav -d BA236288*A6B76B4C9B7# dtmftest.wav
```
###### Command line arguments for gen

* -t <type>
  * output file type (any other type than raw requires sox).
  * allowed types: raw aiff au hcom sf voc cdr dat smp wav maud vwe

*       -a <ampl>
  * amplitude.

*       -d <str>
              encode DTMF string.

*       -z <str>
              encode ZVEI string.

*       -s <freq>
              encode sine of given frequency.

* -p <text>
  * encode hdlc packet using specified text.
