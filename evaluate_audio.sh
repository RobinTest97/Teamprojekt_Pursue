#!/bin/bash
#requires the ALSA Loopback Device ($sudo modprobe snd-aloop)

#Record and play on the Loopback device
arecord -D hw:1,0,1 -f cd -r $2 recorded.wav &
sleep 0.5
aplay -D hw:1,1,1 $1
pkill -f arecord
sleep 1

#determine length of the original audiofile
LENGTH=$(soxi -D $1)
#offset to remove at the end of the file
LENGTH=$(echo "$LENGTH - 0.008353" | bc)

#cut the recorded audiofile to match with the original
ffmpeg -ss 0.49159 -i recorded.wav -c copy -t $LENGTH -y cut_recorded.wav
sleep 1

#compare the audiofiles (requires peaqb)
sudo /usr/local/bin/./peaqb -r $1 -t cut_recorded.wav
exit
