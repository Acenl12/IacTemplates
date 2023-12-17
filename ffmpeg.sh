#!/bin/bash

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
  echo "Error: ffmpeg is not installed. Please install it before running this script."
  exit 1
fi

# Find all MP4 files in the current directory
mp4_files=($(find . -maxdepth 1 -type f -name "*.mp4"))

# Check if there are any MP4 files
if [ ${#mp4_files[@]} -eq 0 ]; then
  echo "No MP4 files found in the current directory."
  exit 1
fi

# Prompt the user for an output file name
read -p "Enter the name for the combined MP4 file (without extension): " output_filename

# Ensure the output filename ends with ".mp4"
output_filename="${output_filename%.mp4}.mp4"

# Combine input MP4 files using ffmpeg
ffmpeg -f concat -safe 0 -i <(for file in "${mp4_files[@]}"; do echo "file '$(realpath "$file")'"; done) -c copy "$output_filename"

if [ $? -eq 0 ]; then
  echo "Combination complete. Output file: $output_filename"
else
  echo "Error occurred during combination. Please check your input files and try again."
fi
