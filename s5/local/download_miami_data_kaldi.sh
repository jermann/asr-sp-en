#! /bin/bash

# start by downloading their repository
DIRECTORY="data/miami/BangorTalk"
if [ ! -d "$DIRECTORY" ]; then
    echo "Cloning corpus"
    cd data/miami
    git clone https://github.com/JIE-CHI/BangorTalk.git
    python3 BangorTalk/download.py --data_dir ./ --corpora miami
    cd ../../
fi
