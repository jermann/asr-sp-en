import os
import glob
import subprocess
from multiprocessing import Pool, cpu_count

def convert_to_mono(input_file):
    output_file = os.path.splitext(input_file)[0] + "_mono.wav"
    command = f'ffmpeg -i "{input_file}" -acodec pcm_s16le -ac 1 -ar 16000 "{output_file}"'
    subprocess.run(command, shell=True, check=True)
    return output_file

def convert_folder_to_mono(folder):
    wav_files = glob.glob(os.path.join(folder, '**/*.wav'), recursive=True)
    with Pool(processes=cpu_count()) as pool:
        mono_files = pool.map(convert_to_mono, wav_files)
    # Optionally remove the original stereo files
    # for wav_file in wav_files:
    #     os.remove(wav_file)
    return mono_files

if __name__ == "__main__":
    directory = "/home/apj2125/kaldi-trunk/egs/asr-sp-en/s5/data/miami/bangortalk/miami"
    mono_files = convert_folder_to_mono(directory)
    print("Conversion completed. Mono files:", len(mono_files))
