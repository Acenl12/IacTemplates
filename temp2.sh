#!/bin/bash

# Create an array of files sorted by size in descending order
files=($(ls -S *.mp4))

for file in "${files[@]}"; do
    if [ -e "$file" ]; then
        output_file="${file%.*}_x265.mp4"
        ffmpeg -i "$file" -c:v libx265 -crf 28 -c:a aac -b:a 128k "$output_file"
        echo "Converted: $file to $output_file"
    fi
done
