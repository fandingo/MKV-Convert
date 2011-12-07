#!/bin/bash

TMPDIR=/tmp/tmpfs
n=1

function audio {
    suf='aac'
    if [ $2 = 'A_AC3' ]; then
	mkvextract tracks "$file" $1:$TMPDIR/a.ac3 #~~!
	while [ -f "$TMPDIR/$$-$n.$suf" ]; do
	    n=$(expr $n + 1)
	done
	ffmpeg -i $TMPDIR/a.ac3 -strict experimental -acodec aac -ab 384k $TMPDIR/$$-$n.aac #~~!
#	mplayer -ao pcm:file=a.wav:fast a.ac3 
#	faac -o "aud-$n.aac" a.wav
       	rm $TMPDIR/a.ac3
    elif [ $2 = 'A_AAC' ]; then
	while [ -f "$TMPDIR/$$-$n.$suf" ]; do
	    n=$(expr $n '+' 1)
	done
	mkvextract tracks "$file" $1:$TMPDIR/$$-$n.aac #~~!
    elif [ $2 = 'A_MPEG/L3' ]; then
	suf='mp3'
	while [ -f "$TMPDIR/$$-$n.$suf" ]; do
	    n=$(expr $n '+' 1)
	done
	mkvextract tracks "$file" $1:$TMPDIR/$$-$n.mp3 #~~!
    fi
    tracks+=" -add $TMPDIR/$$-$n.$suf"
}

function convertmkv {
    directory=$(dirname "$file")
    title=$(basename "$file" .mkv)
    declare -a trackinfo=($(mkvinfo "$file" | egrep '(Track (type|number))|(Codec ID)' | gawk -F ':' '{print $2}'))
    declare -a tracks
    for i in $(seq 0 $(expr "${#trackinfo[@]}" / 3 - 1)); do 
	num=$(expr $i '*' 3)
	t=$(expr $i '+' 1)
	ttype="${trackinfo[$num + 1]}"
	codec="${trackinfo[$num + 2]}"
	fps=$(mkvinfo "$file" | grep duration | sed 's/.*(//' | sed 's/f.*//' | head -n 1)

	if [ $ttype = 'audio' ]; then
	    echo -e "\n\nstarting audio\n\n"
	    audio $t $codec
	elif [ $ttype = 'subtitles' ]; then
	    suf="srt"
	    while [ -f "$TMPDIR/$$-$n.$suf" ]; do
		n=$(expr $n '+' 1)
	    done	
	    echo -e "\n\nStarting subtitles\n\n"
	    mkvextract tracks "$file" $t:$TMPDIR/$$-$n.srt #~~!
	    tracks+=" -add $TMPDIR/$$-$n.srt"
	elif [ $ttype = 'video' ]; then
	    suf="264"
	    while [ -f "$TMPDIR$$-$n.$suf" ]; do
		n=$(expr $n '+' 1)
	    done
	    echo -e "\n\nStarting video\n\n"
	    mkvextract tracks "$file" $t:$TMPDIR/$$-$n.264 #~~!
	    tracks+=" -add $TMPDIR/$$-$n.264"
	fi

    done
    echo -e "Temp files\n$(ls $TMPDIR/)"
    mp="MP4Box -tmp $TMPDIR -new \"$directory/$title.m4v\" -fps $fps ${tracks[@]}"
    echo -e "\n\nMP4Box $mp\n\n"
    sleep 10
    eval $mp #~~!1
    r=$(echo "${tracks[@]}" | sed 's/-add //g')
    rm $r
    # rm "file"
    echo "$directory/$title.m4v" >> /tmp/conversions.log
}

file="$@"
if [ ! -f "$file" ]; then
    echo "Invalid file: $file"
    exit 1
fi
convertmkv
if [ -f "$directory/$title.m4v" ]; then
    echo "Converted $title"
else
    echo "Failed to convert $title"
fi