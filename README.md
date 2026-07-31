# Pibiko Cybiko Pybiko Cyberdeck

## Pibiko

It's a Raspberry Pi Zero W inside a...

## Cybiko (Xtreme)

That Y2K toy that all the kids wanted, years before most smartphones, now controlled with...

## Pybiko

The Python module that hijacks the Cybiko as a dumb terminal and turns it into a

## Cyberdeck

It's cool, it's hip, it's funky old fresh!

## Alex, wtf.

Yea, I know. But hear me out. I'm also gearing to tap into the 900MHz chip directly and turn this whole thing into a defcon talk.

### ???

WIP

## How?

TODO: Upload photos and schematics

Set up a Raspberry Pi Zero W with a headless raspbian image.

Make the user 'pi' and set a password. Set it up for SSH and WiFi.

```bash
# Set up the toolchain
git clone --recursive https://github.com/amovitz/Cybiko-Deck src
cd src
./setup.sh # and wait for close to 3 days with a heatsink on, no I'm not joking. Just for fun you have to enter a sudo password at the end.

# Build the Cybiko App
cd CybikoTUI
./build.sh

# Flash and run the app
cd ../Pybiko
python3 Pybiko.py
```

Congrats! You've got a Cybiko's face stitched onto a Raspberry Pi, your monster is complete.