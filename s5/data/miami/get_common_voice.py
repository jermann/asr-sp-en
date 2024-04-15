from datasets import load_dataset
from pydub import AudioSegment
import os
import io

def main():
    # Load the dataset split
    dataset = load_dataset("mozilla-foundation/common_voice_16_1", "en", split="dev")

    # Directory where the audio files will be saved
    output_dir = 'cv_16-1_en_audio'
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Process each record in the dataset
    for i, record in enumerate(dataset):
        # Path to save the audio file
        file_path = os.path.join(output_dir, f"{record['client_id']}_{i}.mp3")

        # Assuming the audio is already in mp3 format and is stored as a binary array in record['audio']['array']
        audio = AudioSegment.from_file(io.BytesIO(record['audio']['array']), format="mp3")
        audio.export(file_path, format="mp3")

        print(f"Saved {file_path}")

if __name__ == "__main__":
    main()
