#!/bin/bash

find . -type f | grep '.mkv$' | while read file; do
    directory=`dirname "$file"`
    title=`basename "$file" .mkv`
    AC3=`mkvinfo "$file" | grep AC3` #check if it's AC3 audio or DTS
    AAC=`mkvinfo "$file" | grep AAC`
    order=`mkvinfo "$file" | grep "Track type" | sed 's/.*://' | head -n 1 | tr -d " "` #check if the video track is first or the audio track
    if [ "$order" = "video" ]; then
        fps=`mkvinfo "$file" | grep duration | sed 's/.*(//' | sed 's/f.*//' | head -n 1` #store the fps of the video track
	if [ -n "$AC3" ]; then
	    mkvextract tracks "$file" 1:"${title}".264 2:"${title}".ac3 
	    mplayer -ao pcm:file="${title}".wav:fast "${title}".ac3
	    faac -o "${title}".aac "${title}".wav
	elif [ -n "$AAC" ]; then
	    mkvextract tracks "$file" 1:"${title}".264 2:"${title}".aac
	else
	    mkvextract tracks "$file" 1:"${title}".264 2:"${title}".dts
	    ffmpeg -i "${title}".dts -acodec libfaac -ab 576k "${title}".aac
	fi
    else
	fps=`mkvinfo "$file" | grep duration | sed 's/.*(//' | sed 's/f.*//' | tail -n 1`
	if [ -n "$AC3" ]; then
	    mkvextract tracks "$file" 1:"${title}".ac3 2:"${title}".264
	    mplayer -ao pcm:file="${title}".wav:fast "${title}".ac3
	    faac -o "${title}".aac "${title}".wav
	elif [ -n "$AAC" ]; then
	    mkvextract tracks "$file" 1:"${title}".264 2:"${title}".aac
	else
	    mkvextract tracks "$file" 1:"${title}".dts 2:"${title}".264
	    ffmpeg -i "${title}".dts -acodec libfaac -ab 576k "${title}".aac
	fi
    fi
    mkvextract tracks Deadwood.S01E01.720p.BluRay.x264-CtrlHD.mkv 4:"${title}".srt
    MP4Box -tmp /var/media/tmp -new "${directory}/${title}".mp4 -add "${title}".264 -add "${title}".aac -add "${title}".srt -fps $fps
    rm -f "$title".aac "$title".dts "$title".ac3 "$title".264 "${title}".wav "${title}".srt
  # if [ -f "${directory}/${title}".mp4 ]; then
  # rm -f "$file"
  # fi
done





