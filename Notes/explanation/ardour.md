# TL;DR

Notes on setting-up [ardour](https://ardour.org) to record audio.

# Problem and Audience

<audio controls src="https://apps.frickjack.com/assets/audio/podcasts/2021/ardourSbt20210704/ardourSbt20210704.mp3">
Your browser does not support the <code>audio</code> element.
</audio>

A broad selection of digital audio workstation (DAW) software are available for Mac and Windows computers including [logic pro](https://www.apple.com/logic-pro/), [abelton live](https://www.ableton.com/en/), and [garage band](https://www.apple.com/mac/garageband/).  These popular DAWs are not available on Linux (which I run on my laptop), but [several good DAWs](https://itsubuntu.com/best-digital-audio-workstation-apps-for-linux/) do run on Linux - including [ardour](https://ardour.org).  Ardour has a rich set of features, and I have enjoyed learning to use it for my simple podcast and music recording production needs.  Ardour is open source (GPL) software, and I started by using the free version available from Ubuntu's package repository. I was so impressed with the software, that I eventually made a contribution on [ardour.org](https://ardour.org) to support the team's development efforts and get access to their more recent binary releases.

There are a few Ardour tips and tricks that I learned over my first week experimenting with ardour.  First, I installed the [JACK](https://jackaudio.org/) audio server.  Ardour also supports using the [ALSA kernel API](https://alsa-project.org/wiki/Main_Page) directly.  I know nothing about audio software, but it seems that JACK (think jacking your guitar into an amp) is the best way to route sound streams between applications on linux, although a lot of software still relies on the older [pulse audio](https://www.freedesktop.org/wiki/Software/PulseAudio/) sound server.

```
$ sudo apt install jack2 -y
```

Next, for some reason ardour wants to pin its memory, so I updated my system's limit on locked memory.  On my ubuntu laptop I did the following:

```
$ ulimit --help | grep -- -l
      -l	the maximum size a process may lock into memory

$ sudo cat - > /etc/security/limits.d/audio.conf <<EOM
# Provided by the jackd package.
#
# Changes to this file will be preserved.
#
# If you want to enable/disable realtime permissions, run
#
#    dpkg-reconfigure -p high jackd

@audio   -  rtprio     95
@audio   -  memlock    unlimited
#@audio   -  nice      -19
EOM

$ sudo usermod -a -G audio $USER

# log-out and log back in for the change to take effect
```

I am currently just recording with the laptop's built in microphone, and it turns out (on my laptop anyway) that the microphone's input volume is a little low to pick up a guitar playing nearby.  Ubuntu 20 includes Gnome's Settings app that in turn includes a sound-settings tool with a slider for adjusting the mic.

Finally, when recording an audio track via the laptop's microphone, we can prevent feedback from the track's monitor (the laptop's speakers) by either monitoring a null input, or sending the monitor output to a device that does not feedback to the microphone (like headphones).  An ardour audio track's mixer can be configured to monitor the track's audio input (microphone) or disk input (the files where samples are stored).  Configuring the mixer to monitor the disk input effectively sends a null signal to the monitor when recording a new sample.  Using headphones or muting the speakers also prevents feedback.

## Down the Gear Rabbit Hole

I first became interested in audio production after watching some studio-setup videos on Youtube guitar channels like [Paul Davids](https://www.youtube.com/watch?v=PWjfYvf0fsw) and [Rhett Shull](https://www.youtube.com/watch?v=-z_CWpNq8oo).  Suppose you want to record a little guitar performance to an mp3 - how would you do that?  First, you can just record directly to an audio-capture app on your phone, tablet, or computer.  The cost for that is $0 - great!

Next, you want to be able to edit your recording, maybe record some commentary, maybe publish a podcast.  You can use Garage Band or Ardour or some other inexpensive DAW software - cost for that is $0 to $50 - great!

Maybe you now want to get a good microphone.  You could get a USB microphone to record a single channel directly into the DAW - something like the [RODE NT USB](https://smile.amazon.com/Rode-NT-USB-Versatile-Studio-Quality-Microphone/dp/B00KQPGRRE/) looks pretty awesome for $170.

One problem with a USB microphone is that you can't use it as an input to an [amp](https://www.sweetwater.com/store/detail/AcoustaS40--fender-acoustasonic-40-40-watt-acoustic-amp) or a [PA](https://www.fender.com/en-US/audio/sound-systems-1/passport-venue-series-2/6944000000.html), and you are under the impression that things get [a little messy](https://www.microphoneauthority.com/how-to-connect-multiple-usb-microphones-to-a-computer/) if you try to plug two or more usb mic's into a computer to record multiple channels simultaneously.  A better option might be to buy a digital audio interface - something like [this Focusrite](https://smile.amazon.com/gp/product/B07QR73T66/) is $170, then get a couple regular microphones - this [Rode NT1 kit](https://www.sweetwater.com/store/detail/NT1Kit--rode-nt1-kit-condenser-microphone-with-smr-shock-mount-and-pop-filter) includes a mic mount and pop filter for $269, and don't forget to get a mic stand - Amazon basics has [one](https://smile.amazon.com/gp/product/B019NY2PKG/) for $18.

Of course now that you have a couple nice microphones, then you'll want to get some good monitor speakers (maybe $100 or $200) and headphones ([these](https://smile.amazon.com/OneOdio-Adapter-Free-Headphones-Professional-Telescopic/dp/B01N6ZJH96/) are $30) to plug into that audio interface.  You could then record loops to background tracks, and perform along by playing the background tracks through the monitors!

Now you're on your way to spending $1000 and who knows how much time on audio production, and you think - what kind of cameras and software would you need to capture video to publish to Youtube?  Plus, maybe you need a nicer acoustic guitar with an audio pickup you can plug directly into the audio interface?  Or an electric guitar with an amp?  Or maybe try software modeling amps in the DAW?  But you really suck at playing guitar.  But recording a performance is a great way to practice an instrument - forces you to get it right.  That microphone is really entry level - a better one would show how you suck much more clearly.  Maybe you should get a keyboard to control MIDI synthesizers in the DAW - how does that work anyway?  You need a bigger room for all this gear - maybe get an acoustic treatment for the room; make it a real little studio.  You should really get a dedicated computer for production.

And they got you!

# Summary

[Ardour](https://ardour.org) is a nice DAW package for Linux that is easy to get started with.
