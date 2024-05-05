# Created by: apj2125
# Description: Phoneme mapping to convert ARPAbet to IPA

import sys
from convertextract.phonetics import arpabet_to_ipa

def convert_arpabet_to_ipa(arpabet_string):
    # Split the input string by spaces to handle multiple phonemes
    phonemes = arpabet_string.strip().split()
    # Convert each ARPAbet phoneme to IPA
    ipa_transcription = [arpabet_to_ipa(phoneme) for phoneme in phonemes]
    # Join the IPA phonemes with space and return
    return ' '.join(ipa_transcription)

if __name__ == "__main__":
    # Read ARPAbet transcription from command line argument
    if len(sys.argv) > 1:
        arpabet_input = sys.argv[1]
        # Perform the conversion
        ipa_output = convert_arpabet_to_ipa(arpabet_input)
        print("IPA Transcription:", ipa_output)
    else:
        print("Please provide the ARPAbet transcription as an argument.")
