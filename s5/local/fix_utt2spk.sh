#!/bin/bash

# Author: apj2125
# Description: This file uses wav.scp to fix utt2spk

# Define the input and output file names
input_file="data/miami/bangortalk/wav.scp"
output_file="data/miami/bangortalk/utt2spk-fix"

# Process each line in the input file
while IFS=$'\t' read -r utterance_id file_path; do
    # Extract the first part of the utterance ID
    prefix=$(echo "$utterance_id" | cut -d'-' -f1)

    # Write the formatted output to the new file
    echo "$utterance_id $prefix" >> "$output_file"
done < "$input_file"
