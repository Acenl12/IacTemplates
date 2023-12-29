#!/bin/bash
shopt -s globstar # Enable recursive globbing
# Find all mp4 files recursively and store them in an array
mapfile -d $'\0' mp4_files < <(find . -type f -name "*.mp4" -print0)
# Sort the array by file size in descending order
IFS=$'\n' mp4_files=($(du -b "${mp4_files[@]}" 2>/dev/null | sort -nr | cut -f2-))
# Loop through the sorted array and encode each file
for file in "${mp4_files[@]}"; do
    output_file="${file%.*}_x265.mp4"
    handbrake-cli --input "$file" --output "$output_file" --encoder x265 --quality 21 --audio 1,1 --aencoder ca_aac,av_aac --ab 128,128
    echo "Converted: $file to $output_file"
done
