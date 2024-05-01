def convert_to_mono_file(input_filename):
    filename, path = input_filename.strip().split(' ')
    output_filename = filename + "_mono.wav"
    return f"{filename} {path[:-4]}_mono.wav\n"

def convert_file_format(input_file, output_file):
    with open(input_file, 'r') as f_input:
        with open(output_file, 'w') as f_output:
            for line in f_input:
                converted_line = convert_to_mono_file(line)
                f_output.write(converted_line)

if __name__ == "__main__":
    input_file = "/home/apj2125/kaldi-trunk/egs/asr-sp-en/s5/data/miami/train_cleaned/wav.scp"  # Replace with the path to your input file
    output_file = "/home/apj2125/kaldi-trunk/egs/asr-sp-en/s5/data/miami/train_cleaned/wav_mono.scp"  # Replace with the path to your output file
    convert_file_format(input_file, output_file)
    print("Conversion completed.")
