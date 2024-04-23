#!/usr/bin/env bash
#
# Based mostly on the Switchboard recipe. The training database is TED-LIUM,
# it consists of TED talks with cleaned automatic transcripts:
#
# https://lium.univ-lemans.fr/ted-lium3/
# http://www.openslr.org/resources (Mirror).
#
# The data is distributed under 'Creative Commons BY-NC-ND 3.0' license,
# which allow free non-commercial use, while only a citation is required.
#
# Copyright  2014  Nickolay V. Shmyrev
#            2014  Brno University of Technology (Author: Karel Vesely)
#            2016  Vincent Nguyen
#            2016  Johns Hopkins University (Author: Daniel Povey)
#            2018  François Hernandez
#
# Apache 2.0
#
# Project by Alexander Jermann (apj2125)
#

. ./path.sh || exit 1
. ./cmd.sh || exit 1

set -e -o pipefail -u

nj=8
decode_nj=8    # note: should not be >38 which is the number of speakers in the dev set
               # after applying --seconds-per-spk-max 180.  We decode with 4 threads, so
               # this will be too many jobs if you're using run.pl.
stage=6
train_rnnlm=false
train_lm=false

. utils/parse_options.sh || exit 1
[[ $# -ge 1 ]] && { echo "Wrong arguments!"; exit 1; }

echo
echo "===== PREPARING ACOUSTIC DATA ====="
echo
# Needs to be prepared by hand (or using self written scripts):
#
# spk2gender  [<speaker-id> <gender>]
# wav.scp     [<uterranceID> <full_path_to_audio_file>]
# text        [<uterranceID> <text_transcription>]
# utt2spk     [<uterranceID> <speakerID>]
# corpus.txt  [<text_transcription>]

# Data preparation
if [ $stage -le 0 ]; then
  # local/download_miami_data.sh
  # python3 local/process_miami_data.py
  # python3 local/create_test_sets.py

  # INSERT script to add absolute path to wav.scp
  # local/download_miami_data_kaldi.sh
  # local/fix_utt2spk.sh
  # utils/utt2spk_to_spk2utt.pl data/miami/bangortalk/utt2spk > data/miami/bangortalk/spk2utt
  # cat data/miami/bangortalk/text_cs data/miami/bangortalk/text_en data/miami/bangortalk/text_spa > data/miami/bangortalk/text
  # sort -o data/miami/bangortalk/text data/miami/bangortalk/text
  local/make_train_test.sh

  # local/download_commonvoice.sh
fi

if [ $stage -le 2 ]; then
  # local/prepare_dict.sh
fi

# Train Language Model here

# Feature extraction
if [ $stage -le 6 ]; then
  for set in test train; do
    dir=data/$set
    steps/make_mfcc.sh --nj 8 --cmd "$train_cmd" $dir
    steps/compute_cmvn_stats.sh $dir
  done
fi


echo
echo "===== run.sh script is finished ====="
echo
echo "$0: success."
exit 0
