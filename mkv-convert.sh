#!/bin/bash

TMPDIR=/tmp/tmpfs

function tracknum {
    a=1
    while [ -f "$2-$a.$1" ]; do
	a=$(expr $a + 1)
    done
    return $a
}

function audio {
    suf='aac'
    if [ $2 = 'A_AC3' ]; then
	mkvextract tracks "$file" $1:$TMPDIR/a.ac3 &> /dev/null
	tracknum aac aud
	n=$?
	ffmpeg -i $TMPDIR/a.ac3 -strict experimental -acodec aac -ab 384k $TMPDIR/aud-$n.aac &> /dev/null
#	mplayer -ao pcm:file=a.wav:fast a.ac3 
#	faac -o "aud-$n.aac" a.wav
       	rm $TMPDIR/a.ac3
    elif [ $2 = 'A_AAC' ]; then
	tracknum aac aud
	n=$?
	mkvextract tracks "$file" $1:$TMPDIR/aud-$n.aac &> /dev/null
    elif [ $2 = 'A_MPEG/L3' ]; then
	tracknum mp3 aud
	n=$?
	suf='mp3'
	mkvextract tracks "$file" $1:$TMPDIR/aud-$n.mp3 &> /dev/null
    fi
    tracks+=" -add $TMPDIR/aud-$n.$suf"
}

find . -type f -name '*.mkv' | while read file; do
    echo "Converting $file"
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
	    audio $t $codec
	elif [ $ttype = 'subtitles' ]; then
	    tracknum srt sub
	    n=$?
	    mkvextract tracks "$file" $t:$TMPDIR/sub-$n.srt &> /dev/null
	    tracks+=" -add $TMPDIR/sub-$n.srt"
	elif [ $ttype = 'video' ]; then
	    tracknum 264 vid
	    n=$?
	    mkvextract tracks "$file" $t:$TMPDIR/vid-$n.264 &> /dev/null
	    tracks+=" -add $TMPDIR/vid-$n.264"
	fi

    done
    mp="MP4Box -tmp $TMPDIR -new \"$directory\"/\"$title\".m4v -fps $fps ${tracks[@]}"
    echo "MP: $mp"
    eval $mp &> /dev/null
    echo "MP exit: $?"
    r=$(echo "${tracks[@]}" | sed 's/-add //g')
    echo "Remove: $r"
    rm $r
    # rm "file"
    tracks=()
done
