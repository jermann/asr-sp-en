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
decode_nj=8

stage=3
train_rnnlm=false
train_lm=true

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

# DONE
# Data preparation
if [ $stage -le 0 ]; then
  # ====== Download Miami =======
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

  # ==== Set-Up Commonvoice =====
  # local/download_commonvoice.sh
fi

# DONE
if [ $stage -le 2 ]; then
  #local/prepare_dict.sh

  # Check that data dirs are okay!
  utils/validate_data_dir.sh --no-feats $dir || exit 1
fi

# make dict be ARPA

# DONE
if [ $stage -le 3 ]; then
  utils/prepare_lang.sh data/local/dict \
    "<unk>" data/local/lang_nosp data/lang_nosp
fi

# Train Language Model here
  # Download Twitter corpus
  # Clean Twitter corpus
  # Tag Twitter corpus

# Train LM
if [ $stage -le 4 ]; then
  if $train_lm; then
    local/train_lm.sh
  else
    echo "ERROR: Train LM, not download"
    #local/ted_download_lm.sh
  fi
fi

# # Format LM
if [ $stage -le 5 ]; then
  local/format_lms.sh
fi

# Feature extraction
# if [ $stage -le 6 ]; then
#   for set in test train; do
#     dir=data/miami/$set
#     steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" $dir
#     steps/compute_cmvn_stats.sh $dir
#   done
# fi


echo
echo "===== run.sh script is finished ====="
echo
echo "$0: success."
exit 0
