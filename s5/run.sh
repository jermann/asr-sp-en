#!/usr/bin/env bash

# Recipe for Mozilla Common Voice corpus v1
#
# Copyright 2017   Ewald Enzinger
# Apache 2.0
#
# Modified by Alexander Jermann 2024

data_en=$HOME/cv_corpus_v17_en
data_sp=$HOME/cv_corpus_v17_sp

data_url_en=data_url=https://common-voice-data-download.s3.amazonaws.com/cv_corpus_v1.tar.gz
#data_url_sp="https://storage.googleapis.com/common-voice-prod-prod-datasets/cv-corpus-17.0-2024-03-15/cv-corpus-17.0-2024-03-15-es.tar.gz?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Credential=gke-prod%40moz-fx-common-voice-prod.iam.gserviceaccount.com%2F20240414%2Fauto%2Fstorage%2Fgoog4_request&X-Goog-Date=20240414T203246Z&X-Goog-Expires=43200&X-Goog-SignedHeaders=host&X-Goog-Signature=a24434f660a27e60eda612eb959bad4420fa02a5f69cb1a25b9b55ef419df094acf54f4a9d3d0bdaa5ed96af67ec0a390c0bafe64c83d440fa291df9b11969ec0023345f78b42639f0cec0013bfa81a29732da13c87a182f28c25bf18a0388d92cd3a2f7b215d60354053dfe1e1550eaed300896696e859ca84c9b11724eb372541d7477d098e63109c4cc77182f22cc15de73ac3a680e380851b64b93e1c68d29ed1c92074a49fb772cf9e072d20a356584220e410847b1344271e609a7ae1d0edf398ac94720e3b952e1c7721dda04fa6a87114c6a500e4a7c37331af0b26a4fa55e98827f00223e7b3175e2c6aff9ac5c070343a00ba54d2555e3e1173ff2"

. ./cmd.sh
. ./path.sh

stage=0

. ./utils/parse_options.sh

set -euo pipefail

if [ $stage -le 0 ]; then
  mkdir -p $data_en
  mkdir -p $data_sp

  local/download_and_untar.sh $(dirname $data_en) $data_url_en
  #local/download_and_untar.sh $(dirname $data_sp) $data_url_sp
fi

if [ $stage -le 1 ]; then
  for part in valid-train valid-dev valid-test; do
    # use underscore-separated names in data directories.
    local/data_prep.pl $data_en cv-$part data/$(echo $part | tr - _)
    #local/data_prep.pl $data_sp cv-$part data/$(echo $part | tr - _)
  done

  # Prepare ARPA LM and vocabulary using SRILM
  local/prepare_lm.sh data/valid_train
  # Prepare the lexicon and various phone lists
  # Pronunciations for OOV words are obtained using a pre-trained Sequitur model
  local/prepare_dict.sh

  # Prepare data/lang and data/local/lang directories
  utils/prepare_lang.sh data/local/dict \
    '<unk>' data/local/lang data/lang || exit 1

  utils/format_lm.sh data/lang data/local/lm.gz data/local/dict/lexicon.txt data/lang_test/
fi

if [ $stage -le 2 ]; then
  mfccdir=mfcc
  # spread the mfccs over various machines, as this data-set is quite large.
  if [[  $(hostname -f) ==  *.clsp.jhu.edu ]]; then
    mfcc=$(basename mfccdir) # in case was absolute pathname (unlikely), get basename.
    utils/create_split_dir.pl /export/b{07,14,16,17}/$USER/kaldi-data/mfcc/commonvoice/s5/$mfcc/storage \
      $mfccdir/storage
  fi

  for part in valid_train valid_dev valid_test; do
    steps/make_mfcc.sh --cmd "$train_cmd" --nj 20 data/$part exp/make_mfcc/$part $mfccdir
    steps/compute_cmvn_stats.sh data/$part exp/make_mfcc/$part $mfccdir
  done

  # Get the shortest 10000 utterances first because those are more likely
  # to have accurate alignments.
  utils/subset_data_dir.sh --shortest data/valid_train 10000 data/train_10kshort || exit 1;
  utils/subset_data_dir.sh data/valid_train 20000 data/train_20k || exit 1;
fi

# train a monophone system
if [ $stage -le 3 ]; then
  steps/train_mono.sh --boost-silence 1.25 --nj 20 --cmd "$train_cmd" \
    data/train_10kshort data/lang exp/mono || exit 1;
  (
    utils/mkgraph.sh data/lang_test exp/mono exp/mono/graph
    for testset in valid_dev; do
      steps/decode.sh --nj 20 --cmd "$decode_cmd" exp/mono/graph \
        data/$testset exp/mono/decode_$testset
    done
  )&
  steps/align_si.sh --boost-silence 1.25 --nj 10 --cmd "$train_cmd" \
    data/train_20k data/lang exp/mono exp/mono_ali_train_20k
fi

# train a first delta + delta-delta triphone system
if [ $stage -le 4 ]; then
  steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    2000 10000 data/train_20k data/lang exp/mono_ali_train_20k exp/tri1

  # decode using the tri1 model
  (
    utils/mkgraph.sh data/lang_test exp/tri1 exp/tri1/graph
    for testset in valid_dev; do
      steps/decode.sh --nj 20 --cmd "$decode_cmd" exp/tri1/graph \
        data/$testset exp/tri1/decode_$testset
    done
  )&

  steps/align_si.sh --nj 10 --cmd "$train_cmd" \
    data/train_20k data/lang exp/tri1 exp/tri1_ali_train_20k
fi

# train an LDA+MLLT system.
if [ $stage -le 5 ]; then
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
    --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
    data/train_20k data/lang exp/tri1_ali_train_20k exp/tri2b

  # decode using the LDA+MLLT model
  utils/mkgraph.sh data/lang_test exp/tri2b exp/tri2b/graph
  (
    for testset in valid_dev; do
      steps/decode.sh --nj 20 --cmd "$decode_cmd" exp/tri2b/graph \
        data/$testset exp/tri2b/decode_$testset
    done
  )&

  # Align utts using the tri2b model
  steps/align_si.sh --nj 10 --cmd "$train_cmd" --use-graphs true \
    data/train_20k data/lang exp/tri2b exp/tri2b_ali_train_20k
fi

# Train tri3b, which is LDA+MLLT+SAT
if [ $stage -le 6 ]; then
  steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
    data/train_20k data/lang exp/tri2b_ali_train_20k exp/tri3b

  # decode using the tri3b model
  (
    utils/mkgraph.sh data/lang_test exp/tri3b exp/tri3b/graph
    for testset in valid_dev; do
      steps/decode_fmllr.sh --nj 10 --cmd "$decode_cmd" \
        exp/tri3b/graph data/$testset exp/tri3b/decode_$testset
    done
  )&
fi

if [ $stage -le 7 ]; then
  # Align utts in the full training set using the tri3b model
  steps/align_fmllr.sh --nj 20 --cmd "$train_cmd" \
    data/valid_train data/lang \
    exp/tri3b exp/tri3b_ali_valid_train

  # train another LDA+MLLT+SAT system on the entire training set
  steps/train_sat.sh  --cmd "$train_cmd" 4200 40000 \
    data/valid_train data/lang \
    exp/tri3b_ali_valid_train exp/tri4b

  # decode using the tri4b model
  (
    utils/mkgraph.sh data/lang_test exp/tri4b exp/tri4b/graph
    for testset in valid_dev; do
      steps/decode_fmllr.sh --nj 20 --cmd "$decode_cmd" \
        exp/tri4b/graph data/$testset \
        exp/tri4b/decode_$testset
    done
  )&
fi

# Train a chain model
if [ $stage -le 8 ]; then
  local/chain/run_tdnn.sh --stage 0
fi

# Don't finish until all background decoding jobs are finished.
wait
