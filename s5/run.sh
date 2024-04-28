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


### Settings ###

. ./path.sh || exit 1
. ./cmd.sh || exit 1

set -e -o pipefail -u

nj=8
decode_nj=8
lm_order=3

stage=5
train_rnnlm=false
train_lm=true

. utils/parse_options.sh || exit 1
[[ $# -ge 1 ]] && { echo "Wrong arguments!"; exit 1; }


### Stages ###

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
  #local/download_commonvoice.sh
fi
echo
echo "===== FEATURES EXTRACTION ====="
echo
if [ $stage -le 1 ]; then
  for set in test train; do
    dir=data/miami/$set
    steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" $dir
    steps/compute_cmvn_stats.sh $dir
  done
fi

echo
echo "===== PREPARING LANGUAGE DATA ====="
echo
# Needs to be prepared by hand (or using self written scripts):
#
# lexicon.txt           [<word> <phone 1> <phone 2> ...]
# nonsilence_phones.txt [<phone>]
# silence_phones.txt    [<phone>]
# optional_silence.txt  [<phone>]
# Preparing language data
if [ $stage -le 2 ]; then
  #local/prepare_dict.sh

  # Check that data dirs are okay!
  utils/validate_data_dir.sh --no-feats $dir || exit 1
fi
if [ $stage -le 3 ]; then
  utils/prepare_lang.sh data/local/dict "<unk>" data/local/lang data/lang
fi

echo
echo "===== TRAINING LM ====="
echo "===== MAKING lm.arpa ====="
echo
if [ $stage -le 4 ]; then
  loc=`which ngram-count`;
  if [ -z $loc ]; then
          if uname -a | grep 64 >/dev/null; then
                  sdir=$KALDI_ROOT/tools/srilm/bin/i686-m64
          else
                          sdir=$KALDI_ROOT/tools/srilm/bin/i686
          fi
          if [ -f $sdir/ngram-count ]; then
                          echo "Using SRILM language modelling tool from $sdir"
                          export PATH=$PATH:$sdir
          else
                          echo "SRILM toolkit is probably not installed.
                                  Instructions: tools/install_srilm.sh"
                          exit 1
          fi
  fi
  local=data/local
  mkdir $local/tmp
  ngram-count -order $lm_order -write-vocab $local/tmp/vocab-full.txt -wbdiscount -text $local/corpus.txt -lm $local/tmp/lm.arpa
fi
echo
echo "===== MAKING G.fst ====="
echo
if [ $stage -le 5 ]; then
  lang=data/lang
  $KALDI_ROOT/src/lmbin/arpa2fst --disambig-symbol=#0 --read-symbol-table=$lang/words.txt $local/tmp/lm.arpa $lang/G.fst
fi
echo
echo "===== MONO TRAINING ====="
echo
steps/train_mono.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/mono  || exit 1
echo
echo "===== MONO DECODING ====="
echo
utils/mkgraph.sh --mono data/lang exp/mono exp/mono/graph || exit 1
steps/decode.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" exp/mono/graph data/test exp/mono/decode
echo
echo "===== MONO ALIGNMENT ====="
echo
steps/align_si.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/mono exp/mono_ali || exit 1
echo
echo "===== TRI1 (first triphone pass) TRAINING ====="
echo
steps/train_deltas.sh --cmd "$train_cmd" 2000 11000 data/train data/lang exp/mono_ali exp/tri1 || exit 1
echo
echo "===== TRI1 (first triphone pass) DECODING ====="
echo
utils/mkgraph.sh data/lang exp/tri1 exp/tri1/graph || exit 1
steps/decode.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" exp/tri1/graph data/test exp/tri1/decode
echo
echo "===== run.sh script is finished ====="
echo

# # Train LM
# if [ $stage -le 4 ]; then
#   if $train_lm; then
#     local/train_lm.sh
#   else
#     echo "ERROR: Train LM, not download"
#     #local/ted_download_lm.sh
#   fi
# fi
#
# # # Format LM
# if [ $stage -le 5 ]; then
#   local/format_lms.sh
# fi




echo
echo "===== run.sh script is finished ====="
echo
echo "$0: success."
exit 0
