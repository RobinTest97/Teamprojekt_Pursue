#!/bin/bash
#this script is the short version of evaluate_audio.sh
#it can only record audio, since the other script is not working properly
#INPUTS: $1 : the filename, needs to be a wav-file, $2 : the framerate, must match the original audiofile framerate


#this needs to be changed based on your system with $pacmd list-sources | egrep '^\s+name:.*\.monitor'
outputDevice="alsa_output.pci-0000_00_05.0.analog-stereo.monitor"
#record the output of the speakers
parecord --channels=2 --rate=$2 -d $outputDevice recorded.wav &
sleep 0.01
#play the specified audiofile
paplay $1
#stop recording
pkill -f parecord
sleep 1
