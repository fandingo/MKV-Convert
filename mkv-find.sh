#!/bin/bash

if [ -f "$@" ]; then
    t=$(echo "$@" | sed 's/\(.*\)\.mkv/\1/')
    if [ ! -f "$t.m4v" ]; then
	echo "$@"
    fi
fi