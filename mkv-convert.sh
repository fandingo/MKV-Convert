#!/bin/bash

if [ ! -d $TMPDIR ]; then
    mkdir $TMPDIR
    tmpexists="true"
fi

TMPDIR=./tmp
n=1


# Extract audio from mkv.
# If audio is not AAC or MP3, transcode it.
function audio {
    suf=$(echo $2 | sed 's/^A_\(.*\)/\L\1/')
    echo "Suf: $suf"
    if [ $2 = 'A_AAC' ] || [ $2 = 'A_MPEG/L3' ]; then
	mkvextract tracks "$file" $1:$TMPDIR/$pid-$n.$suf #~~!
    else
	mkvextract tracks "$file" $1:$TMPDIR/a.$suf #~~!
	ffmpeg -i $TMPDIR/a.$suf -strict experimental -acodec aac -ab 684k $TMPDIR/$pid-$n.aac #~~!
       	rm $TMPDIR/a.$suf
	suf='aac'
    fi
    tracks+=" -add $TMPDIR/$pid-$n.$suf"
}


# Subtitles file may be in external files
# that have the same name.
function externsubs {
    if [ -f "$directory/$title.srt" ]; then
	echo "Found external subtitles"
	cp "$directory/$title.srt" $TMPDIR/$pid-$n.srt
	tracks+=" -add $TMPDIR/$pid-$n.srt"
    fi
}


# Main function
# Iteratte through tracks and extract them.
# Mux them all together at the end
function convertmkv {
    directory=$(dirname "$file")
    title=$(basename "$file" .mkv)
    declare -a trackinfo=($(mkvinfo "$file" | egrep '(Track (type|number))|(Codec ID)' | gawk -F ':' '{print $2}'))
    declare -a tracks
    pid=$$
    for i in $(seq 0 $(expr "${#trackinfo[@]}" / 3 - 1)); do 
	num=$(expr $i '*' 3)
	t=$(expr $i '+' 1)
	ttype="${trackinfo[$num + 1]}"
	codec="${trackinfo[$num + 2]}"
	fps=$(mkvinfo "$file" | grep duration | sed 's/.*(//' | sed 's/f.*//' | head -n 1)

	if [ $ttype = 'audio' ]; then
	    audio $t $codec
	elif [ $ttype = 'subtitles' ]; then
	    suf="srt"
	    mkvextract tracks "$file" $t:$TMPDIR/$pid-$n.srt #~~!
	    tracks+=" -add $TMPDIR/$pid-$n.srt"
	elif [ $ttype = 'video' ]; then
	    suf="264"
	    mkvextract tracks "$file" $t:$TMPDIR/$pid-$n.264 #~~!
	    tracks+=" -add $TMPDIR/$pid-$n.264"
	fi
	n=$(expr $n + 1)
    done
    externsubs
    mp="MP4Box -tmp $TMPDIR -new \"$directory/$title.m4v\" -fps $fps ${tracks[@]}"
    eval $mp #~~!1
    r=$(echo "${tracks[@]}" | sed 's/-add //g')
    rm $r
    echo "$directory/$title.m4v" >> /tmp/conversions.log
}

########
# Main #
########

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

if [ ! -z $tmpexists ]; then
    rm -rf $TMPDIR
fi

#########
# /Main #
#########