#!/bin/bash

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
for file in $(find "." -type f -name "*.mkv" ) ; do
  echo "$f"
  echo "ffmpeg -i \"${file}\" -codec copy \"${file%.mkv}.mp4\""
  ffmpeg -i ${file} -codec copy ${file%.mkv}.mp4 && rm -f ${file}
done
IFS=$SAVEIFS
