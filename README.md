# llifvid
A hack to connect an interactive fiction text adventure game to video playback

## Overview

After listening to the [Eaten By A Grue podcast:19](http://monsterfeet.com/grue/notes/19) about the 
interactive laserdisc-based game for the movie "Rollercoaster", and then following that up with the 
[episode about Hitchhiker's Guide:16](http://monsterfeet.com/grue/notes/16), a spark popped in my
head. It should be possible to somehow "watch" the Hitchhiker's Guide (H2G2) Infocom game and play
clips of the TV show, movie, etc, syncronized to the scenes and what you're looking at.

Just about all of this project is based on existing stuff, but I glued it all together.

* [Frotz](http://frotz.sourceforge.net) - runs the Z-code, in a text-based terminal
* [VLC media Player](https://www.videolan.org/vlc/index.html) - plays back the video
* [H2G2 TV on DVD](https://www.google.com/search?q=buy+hitchhiker%27s+guide+tv+dvds) - the DVDs
* [Netcat](https://en.wikipedia.org/wiki/Netcat) - so my client can talk to the server
* [Tee](https://en.wikipedia.org/wiki/Tee_(command)) - to split the output from frotz
* Perl script (in this repo) - "reads" the text, matches text, tells VLC what to play 

The whole thing kinda works, is buggy, unoptimized, but that's the nature of a 4 hour hack.

## Architecture

(insert diagram here)

This is the basic system... This was a quick sketch I made to get the idea down. Essentially there 
are two halves.

### Server/Video player

The server on the left is essentially a perl script that:
* Matches text from the interactive fiction
* has a simple interpreted language that can perform sequential functions
* outputs "remote" commands for VLC

The output of that perl script is piped into VLC. If you're going to reproduce this, 
be aware that enabling the VLC shell it was a bit tricky, and I didn't document the process. 
I think I needed to enable extended preferences in VLC to see the bit to turn on that feature.

Also on this side are the video files for H2G2 episodes 1 and 2.  I used 
[Handbrake](https://handbrake.fr) to decode them off of my DVDs.  I do know that the episodes
exist online, but those may be set up for web streaming, and will need to be transcoded via
handbrake or some other tool.  It basically just needs to add some information in that isn't there.

For obvious reasons, the video files are not included in this repository.

Netcat (nc) is setup as a listener for the text output from the game engine.  That is piped into the perl script,
whose output is piped into VLC.

If you're doing this, be aware that you will probably have to manually quit out of VLC to make sure 
things might work a second time. ;)

### Client/Game engine

The client on the right is some bash script piping and connection of Frotz with the game file.  I 
used the ms-dos version of the data file, although I do not know if any other versions differ in
any way.  This was just easiest for me to grab without digging out and setting up my Amiga to 
pull the files off of my game's floppy.

For obvious reasons, the game file is not included in this repository.

The output of frotz is piped through tee.  Tee takes the output and splits it to two different places.
First, is the console so you can see what you're doing, but it also usually saves it to a file.  I've 
changed that path to be piping the output to netcat, setup as a transmitter to the serfver.


## Interperter

In the perl script is a quick interpreter that I hacked together to run little micro scripts of code.
I started doing this as an array of arrays, but if you've ever done that in perl, you'd know that 
such things are never good ideas in that language. I briefly considered hopping over to python to 
do it, but I already had stuff done, and was still toying with the idea of having the perl script 
itself listening to a socket, which i was unsure of how to do in python.  So it's in perl.

Anyway, I switched it over to be a plain text blob in the source file.  At startup, it cleans up
the text, removing comments, and empty lines.  It also breaks it up as two elements per line; 
the opcode and the parameter, and store that as the runtime program.  This vastly simplified 
runtime routines.

The two main entry bits for the language are the label and the text match.  It's sort of event
driven, sequential language, with no nesting, no calls, no iterations, none of that... one operation
per line.  I did include comments though which are denoted by pound sign, # and continue 
to the end of the line.  They can be put anywhere, as they are filtered out before runtime.

    : label
Labels are used for 'goto' statements, or calling the goto function to set the current PC (program
counter).  If you call the doGoto() function, it will adjust the PC to the line after that label, 
or to -1, indicating that it was not found, and there's nothing to do.

    ? text to match
This denotes text that should be matched.  As the program runs, it reads in byte by byte from the
client and accumulates it. When it hits a newline 0x0d, or 0x0a, it sends the accumulated text to
the "got a line" function.  That one tries to match each "text to match" string to see if it 
matches any part of the current line.  If it does, it sets the PC to the next line, and returns.

From there, there are a few opcodes that can be called:

    seek 100

This will seek the current video file to 100 seconds in.

    until 110
    
This will wait until the timer hits 110 seconds in in the video.  Due to limitations of time,
this is implemented as a hack.  Instead of looking at the video file to get the time, it remembers
the last 'seek' number called, does a difference, and sleeps for that many seconds, blocking.
For the above two codes the "until 110" call will essentially sleep for 10 seconds

    done

Indicates that a sequence of opcodes is done.  "do until done" will stop here"  this leaves
the PC at -1, indicating it's done.

    player play
    
This sends the "play" command to VLC.  It can send anything. Useful things are:

    play    # press play on the current video
    pause   # toggle pause.  Note; it does NOT always pause! just toggle pause!
    frame   # advance one frame.  This DOES always leave VLC in a paused state
    stop    # stops the player
    fullscreen on  # makes the video full screen (on|off)
    seek 100 # you can manuall call this as well
    add FILENAME   # adds a file to the playlist, and switches to it, playing it
    
These essentially just print out the command, as the VLC shell is consuming the commands directly.

  
