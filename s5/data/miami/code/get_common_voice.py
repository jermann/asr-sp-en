from datasets import load_dataset
from huggingface_hub import hf_hub_download
#from pydub import AudioSegment
import os
import io

def main():
    hf_hub_download(repo_id="mozilla-foundation/common_voice_16_1/audio/en/dev", filename="en_dev_0.tar", repo_type="dataset", local_dir="/home/apj2125/kaldi-trunk/egs/asr-sp-en/s5/data/cv_en")

    # # Ensure ffmpeg is available for pydub to use (check your system path!)
    # AudioSegment.converter = "/usr/bin/ffmpeg"  # Adjust this path to the ffmpeg installation path on your system
    #
    # # Load the dataset split
    # dataset = load_dataset("mozilla-foundation/common_voice_16_1", "en", split="validation")
    #
    # # Directory where the audio files will be saved
    # output_dir = 'cv_16-1_en_audio'
    # if not os.path.exists(output_dir):
    #     os.makedirs(output_dir)
    #
    # # Process each record in the dataset
    # for i, record in enumerate(dataset):
    #     # Path to save the audio file
    #     file_path = os.path.join(output_dir, f"{record['client_id']}_{i}.mp3")
    #
    #     # Assuming the audio is in mp3 format and stored as a binary blob in record['audio']['array']
    #     audio = AudioSegment.from_file(io.BytesIO(record['audio']['array']), format="mp3")
    #     audio.export(file_path, format="mp3")
    #
    #     print(f"Saved {file_path}")

if __name__ == "__main__":
    main()
