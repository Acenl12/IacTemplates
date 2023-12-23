#!/bin/bash

shopt -s globstar # Enable recursive globbing

# Find all mp4 files recursively and store them in an array
mp4_files=($(find . -type f -name "*.mp4"))

# Sort the array by file size in descending order
IFS=$'\n' mp4_files=($(sort -nrk 5 <<<"${mp4_files[*]}"))

# Loop through the sorted array and encode each file
for file in "${mp4_files[@]}"; do
    output_file="${file%.*}_x265.mp4"
    ffmpeg -i "$file" -c:v libx265 -crf 28 -c:a aac -b:a 128k "$output_file"
    echo "Converted: $file to $output_file"
done
