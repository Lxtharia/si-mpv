# Single Instance mpv

## Motivation
I wanted to quickly browse through a long list of Audio files but because it opens a new mpv instance for each file i had to close all of them manually.


## Installation

### Locally (for current user)
Just copy it somewhere in your `$PATH`.
I like `~/.local/bin/mpv`

```bash
git clone https://github.com/Lxtharia/si-mpv
cp si-mpv/scripts/simpv.sh ~/.local/bin/simpv
```

### Globally

```bash
git clone https://github.com/Lxtharia/si-mpv
sudo cp si-mpv/scripts/simpv.sh /usr/bin/simpv
```

### Windows

Eventually potentially

## Usage

This script can be used like mpv, but it will use a running instance of mpv to play new files (but only if this instance has been started with this script)

```bash
# Simply play a mp3 file
simpv ~/Music/MoonlightSonata.mp3 --volume 29

# While the sonata is still running you can do:
# Replace the current playing file
simpv ~/Music/MoneyMachine.mp3
simpv ~/Music/MoneyMachine.mp3 --replace
simpv ~/Music/MoneyMachine.mp3 --playnow

# Queue a file
simpv ~/Music/MoneyMachine.mp3 --append
simpv ~/Music/MoneyMachine.mp3 --queue 

# Queue a file and start playing if the player is paused
simpv ~/Music/MoneyMachine.mp3 --append-play
```

If you want more than one instance or replace specific ones, use different sockets
```bash
simpv ~/Music/MoonlightSonata.mp3 --volume 29 --socket /tmp/mpv_A

# creates a new instance at default socket /tmp/mpv_socket
simpv ~/Music/MoneyMachine.mp3
# creates a new instance at socket /tmp/mpv_A
simpv ~/Music/MoneyMachine.mp3 --socket /tmp/mpv_A
```

## Disclaimer
- I want it be noted that I used ChatGPT for 98% of that because it would have taken me 3 days otherwise to write good and functioning bash


