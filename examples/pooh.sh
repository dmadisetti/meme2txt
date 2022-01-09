#!/usr/bin/env bash
image=~/images/pooh.jpg
meme2txt.sh $image --targetAspect=0.5 --meme "Using text" 9 68 "30m" --meme "$(echo -e "Using\n blocks" | toilet -fsmblock)" 24 66
