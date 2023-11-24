#!/bin/bash

for file in *.mp4; do
    if [ -e "$file" ]; then
        output_file="${file%.*}_x265.mp4"
        ffmpeg -i "$file" -c:v libx265 -crf 28 -c:a aac -b:a 128k "$output_file"
        echo "Converted: $file to $output_file"
    fi
done
