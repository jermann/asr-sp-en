#! /bin/bash

# Created by: apj2125
# Note: Need to have a Huggingface and Log-In to download

# start by downloading commonvoice
DIRECTORY="data/cv"
if [ ! -d "$DIRECTORY" ]; then
    echo "Downloading Huggingface CLI"
    cd data/cv
    pip install -U "huggingface_hub[cli]"
    huggingface-cli login
    echo "Login Succesful"
    echo "Downloading English Commo Voice 16.1 (80 GB)"
    huggingface-cli download mozilla-foundation/common_voice_16_1 --include "audio/en/train/*.tar" --repo-type dataset --local-dir .
    echo "Downloading Spanish Commo Voice 16.1 (55 GB)"
    huggingface-cli download mozilla-foundation/common_voice_16_1 --include "audio/sp/train/*.tar" --repo-type dataset --local-dir .
    echo "Done downloading Common Voice"
    cd ../../
fi
