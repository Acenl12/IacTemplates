import os
import subprocess

def convert_to_x265(input_file, output_file):
    command = ['ffmpeg', '-i', input_file, '-c:v', 'libx265', '-crf', '28', '-c:a', 'aac', '-b:a', '128k', output_file]
    subprocess.run(command)

def convert_all_mp4_to_x265_in_current_directory():
    current_directory = os.getcwd()
    for file in os.listdir(current_directory):
        if file.lower().endswith('.mp4'):
            input_file = os.path.join(current_directory, file)
            output_file = os.path.splitext(input_file)[0] + '_x265.mp4'
            convert_to_x265(input_file, output_file)
            print(f'Converted: {input_file} to {output_file}')

convert_all_mp4_to_x265_in_current_directory()
