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

stage=16
train_rnnlm=false
train_lm=true

. utils/parse_options.sh || exit 1
[[ $# -ge 1 ]] && { echo "Wrong arguments!"; exit 1; }
# delete MFCC
#rm -rf exp data/miami/train/cmvn.scp data/miami/train/feats.scp data/miami/train/split8 data/miami/train/data data/miami/test/cmvn.scp data/miami/test/feats.scp data/miami/test/split8 data/miami/test/data data/local/lang data/lang data/local/tmp data/local/dict/lexiconp.txt
#rm -rf data/local/lm/data/arpa data/local/lm/data/lm_4_prune_big data/local/lm/data/work data/local/lm/data/wordlist_4_train-2_ted-1.pocolm data/local/lm/data/wordlist data/local/lm/data/text/unigram_weights
#rm -rf data/miami/test/frame_shift data/miami/test/utt2dur data/miami/test/utt2num_frames data/miami/test/log data/miami/test/conf
#rm -rf data/miami/train/frame_shift data/miami/train/utt2dur data/miami/train/utt2num_frames data/miami/train/log data/miami/train/conf

### Stages ###

# Needs to be prepared by hand (or using self written scripts):
#
# spk2gender  [<speaker-id> <gender>]
# wav.scp     [<uterranceID> <full_path_to_audio_file>]
# text        [<uterranceID> <text_transcription>]
# utt2spk     [<uterranceID> <speakerID>]
# corpus.txt  [<text_transcription>]
if [ $stage -le 0 ]; then
  echo
  echo "===== PREPARING ACOUSTIC DATA ====="
  echo
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
  # local/make_train_test.sh

  # Verify Data directory
  utils/validate_data_dir.sh --no-feats data/miami/train || exit 1
  utils/validate_data_dir.sh --no-feats data/miami/test || exit 1
  utils/validate_dict_dir.pl data/local/dict || exit 1

  # ==== Set-Up Commonvoice =====
  #local/download_commonvoice.sh
fi
if [ $stage -le 1 ]; then
  echo
  echo "===== FEATURES EXTRACTION ====="
  echo
  for set in test train; do
    dir=data/miami/$set
    steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" $dir
    steps/compute_cmvn_stats.sh $dir
  done
fi


# Needs to be prepared by hand (or using self written scripts):
#
# lexicon.txt           [<word> <phone 1> <phone 2> ...]
# nonsilence_phones.txt [<phone>]
# silence_phones.txt    [<phone>]
# optional_silence.txt  [<phone>]
# Preparing language data
if [ $stage -le 2 ]; then
  echo
  echo "===== PREPARING LANGUAGE DATA ====="
  echo
  # local/prepare_dict.sh
  # Check that data dirs are okay!
  utils/validate_dict_dir.pl data/local/dict || exit 1
fi
if [ $stage -le 3 ]; then
  utils/prepare_lang.sh data/local/dict "<unk>" data/local/lang data/lang
fi

if [ $stage -le 4 ]; then
  echo
  echo "===== TRAINING LM ====="
  echo "===== MAKING lm.arpa ====="
  echo
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
  ngram-count -order $lm_order -write-vocab $local/tmp/vocab-full.txt -wbdiscount -tagged -text $local/lm/data/text/corpus.txt -lm $local/tmp/lm.arpa
fi

if [ $stage -le 5 ]; then
  echo
  echo "===== MAKING G.fst ====="
  echo
  arpa2fst --disambig-symbol=#0 --read-symbol-table=data/lang/words.txt data/local/tmp/lm.arpa data/lang/G.fst
fi

if [ $stage -le 6 ]; then
  echo
  echo "===== MONO TRAINING ====="
  echo
  steps/train_mono.sh --nj $nj --cmd "$train_cmd" data/miami/train data/lang exp/mono  || exit 1
fi
# echo
# echo "===== MONO DECODING ====="
# echo
#utils/mkgraph.sh --mono data/lang exp/mono exp/mono/graph || exit 1
#steps/decode.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" exp/mono/graph data/miami/test exp/mono/decode
if [ $stage -le 7 ]; then
  echo
  echo "===== MONO ALIGNMENT ====="
  echo
  steps/align_si.sh --nj $nj --cmd "$train_cmd" data/miami/train data/lang exp/mono exp/mono_ali || exit 1
fi

if [ $stage -le 8 ]; then
  echo
  echo "===== TRI1 (first triphone pass) TRAINING ====="
  echo
  steps/train_deltas.sh --cmd "$train_cmd" 2000 11000 data/miami/train data/lang exp/mono_ali exp/tri1 || exit 1
fi

if [ $stage -le 9 ]; then
  echo
  echo "===== TRI1 (first triphone pass) DECODING ====="
  echo
  utils/mkgraph.sh data/lang exp/tri1 exp/tri1/graph || exit 1
  steps/decode.sh --config conf/decode.config --nj $decode_nj --cmd "$decode_cmd" --num-threads 4 exp/tri1/graph data/miami/test exp/tri1/decode
fi

if [ $stage -le 10 ]; then
  echo
  echo "===== TRI1 (first triphone pass) LM RESCORE ====="
  echo "Below might not work"
  echo
  utils/build_const_arpa_lm.sh data/local/tmp/lm.arpa.gz data/lang data/lang_rescore || exit 1;
  steps/lmrescore_const_arpa.sh  --cmd "$decode_cmd" data/lang data/lang_rescore data/miami/test exp/tri1/decode exp/tri1/decode_rescore
fi

if [ $stage -le 11 ]; then
  echo
  echo "===== TRI1 & TRI2 (first triphone pass) TRAIN & ALIGN ====="
  echo
  steps/align_si.sh --nj $nj --cmd "$train_cmd" data/miami/train data/lang exp/tri1 exp/tri1_ali
  steps/train_lda_mllt.sh --cmd "$train_cmd" 4000 50000 data/miami/train data/lang exp/tri1_ali exp/tri2
fi

if [ $stage -le 12 ]; then
  echo
  echo "===== TRI1 & TRI2 (first triphone pass) DECODE ====="
  echo
  utils/mkgraph.sh data/lang exp/tri2 exp/tri2/graph
  steps/decode.sh --nj $decode_nj --cmd "$decode_cmd"  --num-threads 4 exp/tri2/graph data/miami/test exp/tri2/decode
  steps/lmrescore_const_arpa.sh  --cmd "$decode_cmd" data/lang data/lang_rescore data/miami/test exp/tri2/decode exp/tri2/decode_rescore
fi

if [ $stage -le 13 ]; then
  echo
  echo "===== REFINE LEXICON ====="
  echo
  steps/get_prons.sh --cmd "$train_cmd" data/miami/train data/lang exp/tri2
  utils/dict_dir_add_pronprobs.sh --max-normalize true data/local/dict exp/tri2/pron_counts_nowb.txt exp/tri2/sil_counts_nowb.txt \
    exp/tri2/pron_bigram_counts_nowb.txt data/local/dict_refined
fi

if [ $stage -le 14 ]; then
  echo
  echo "===== TRAIN REFINED LEXICON ====="
  echo
  utils/prepare_lang.sh data/local/dict_refined "<unk>" data/local/lang_refined data/lang_refined
  cp -rT data/lang_refined data/lang_refined_rescore
  cp data/lang/G.fst data/lang_refined/
  cp data/lang_rescore/G.carpa data/lang_refined_rescore/

  utils/mkgraph.sh data/lang_refined exp/tri2 exp/tri2/graph

  steps/decode.sh --nj $decode_nj --cmd "$decode_cmd"  --num-threads 4 \
    exp/tri2/graph data/miami/test exp/tri2/decode
  steps/lmrescore_const_arpa.sh --cmd "$decode_cmd" data/lang_refined data/lang_refined_rescore \
     data/miami/test exp/tri2/decode exp/tri2/decode_rescore
fi

if [ $stage -le 15 ]; then
  echo
  echo "===== TRAIN SAT GMM ====="
  echo
  steps/align_si.sh --nj $nj --cmd "$train_cmd" data/miami/train data/lang_refined exp/tri2 exp/tri2_ali
  steps/train_sat.sh --cmd "$train_cmd" 5000 100000 data/miami/train data/lang_refined exp/tri2_ali exp/tri3
  utils/mkgraph.sh data/lang_refined exp/tri3 exp/tri3/graph

  steps/decode_fmllr.sh --nj $decode_nj --cmd "$decode_cmd"  --num-threads 4 \
    exp/tri3/graph data/miami/test exp/tri3/decode
  steps/lmrescore_const_arpa.sh --cmd "$decode_cmd" data/lang_refined data/lang_refined_rescore \
     data/miami/test exp/tri3/decode exp/tri3/decode_rescore
fi

if [ $stage -le 16 ]; then
  echo
  echo "===== Clean Up Segmentation ====="
  echo
  local/run_cleanup_segmentation.sh
fi
if [ $stage -le 17 ]; then
  echo
  echo "===== Run TDNN (add GPUs) ====="
  echo
  local/chain/run_tdnn.sh
fi

if [ $stage -le 18 ]; then
  echo
  echo "===== Run RNN-LM TDNN ====="
  echo
  local/rnnlm/tuning/run_lstm_tdnn_a.sh
  local/rnnlm/average_rnnlm.sh
fi

if [ $stage -le 19 ]; then
  # Here we rescore the lattices generated at stage 17
  rnnlm_dir=exp/rnnlm_lstm_tdnn_a_averaged
  lang_dir=data/lang_chain
  ngram_order=4

  # TO-DO: set the directories below

  for dset in test; do
    echo
    echo "===== Rescore TDNN-f Lattice and Output ====="
    echo
    data_dir=data/${dset}_hires
    decoding_dir=exp/chain_cleaned/tdnnf_1a/decode_${dset}
    suffix=$(basename $rnnlm_dir)
    output_dir=${decoding_dir}_$suffix

    rnnlm/lmrescore_pruned.sh \
      --cmd "$decode_cmd --mem 32G" \
      --weight 0.5 --max-ngram-order $ngram_order \
      $lang_dir $rnnlm_dir \
      $data_dir $decoding_dir \
      $output_dir
  done
fi

echo
echo "===== run.sh script is finished ====="
echo
echo "$0: success."
exit 0
