#!/bin/bash


#record the output of the speakers 
parecord --channels=2 --rate=$2 -d alsa_output.pci-0000_00_05.0.analog-stereo.monitor recorded.wav &
sleep 0.01
#play the specified audiofile
paplay $1
#stop recording
pkill -f parecord
sleep 1

#determine frame differences
$(/usr/local/bin/./sndfile-cmp $1 recorded.wav > offset.txt)
offset=$(awk 'NF>1{print $NF}' offset.txt | grep -o '[0-9]\+')

#while loop to remove the offset at the beginning of a audiofile
while [ $offset -eq 0 ]
do
#calculate the new starting position
start=$(echo "$offset+1" |bc)
start1=$(echo "$start*0.0002083" |bc |awk '{printf "%f", $0}')
#cut the old file
ffmpeg -ss $start1 -i recorded.wav -c copy -y cut_recorded.wav
sleep 1
#copy the new file to the old one
ffmpeg -i cut_recorded.wav -c copy -hide_banner -loglevel error -y recorded.wav
sleep 1
#determine new frame differences
$(/usr/local/bin/./sndfile-cmp $1 recorded.wav > offset.txt)
offset=$(awk 'NF>1{print $NF}' offset.txt | grep -o '[0-9]\+')
done
#perform the evaluation
#sudo /usr/local/bin/./peaqb -r $1 -t cut_recorded.wav
exit
