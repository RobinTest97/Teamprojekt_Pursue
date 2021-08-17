#!/bin/bash

parecord --channels=2 --rate=$2 -d alsa_output.pci-0000_00_05.0.analog-stereo.monitor recorded.wav &
sleep 0.01
paplay $1
pkill -f parecord
sleep 1

ffmpeg -i recorded.wav -c copy -hide_banner -loglevel error -y cut_recorded.wav
sleep 1
$(/usr/local/bin/./sndfile-cmp $1 cut_recorded.wav > offset.txt)
offset=$(awk 'NF>1{print $NF}' offset.txt | grep -o '[0-9]\+')
while [ $offset -eq 0 ]
do
start=$(echo "$offset+1" |bc)
start1=$(echo "$start*0.0002083" |bc |awk '{printf "%f", $0}')
ffmpeg -ss $start1 -i cut_recorded.wav -c copy -y recorded.wav
sleep 1
ffmpeg -i recorded.wav -c copy -hide_banner -loglevel error -y cut_recorded.wav
sleep 1
$(/usr/local/bin/./sndfile-cmp $1 cut_recorded.wav > offset.txt)
offset=$(awk 'NF>1{print $NF}' offset.txt | grep -o '[0-9]\+')
done
#sudo /usr/local/bin/./peaqb -r $1 -t cut_recorded.wav
exit
