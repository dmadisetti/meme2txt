#!/usr/bin/env bash
image=~/images/drake.jpg
meme2txt.sh $image --targetAspect=0.5 --meme 'Memes on twitter' 10 68 "30m" --meme "$(echo -e "Memes on\\n CMD" | toilet -fsmblock)" 28 65 "31m"
