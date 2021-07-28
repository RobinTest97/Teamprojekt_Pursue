#!/bin/bash

#Record and play on the Loopback device
arecord -D hw:1,0,1 -f cd -r $2 recorded.wav &
sleep 0.5
aplay -D hw:1,1,1 $1
pkill -f arecord
sleep 1

LENGTH=$(soxi -D $1)
LENGTH=$(echo "$LENGTH - 0.008353" | bc)

ffmpeg -ss 0.49159 -i recorded.wav -c copy -t $LENGTH -y cut_recorded.wav
sleep 1
sudo /usr/local/bin/./peaqb -r $1 -t cut_recorded.wav
exit
