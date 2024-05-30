#!/usr/bin/env bash

# Author: apj2125

# Load Settings
. ./path.sh || exit 1
. ./cmd.sh || exit 1

set -e -o pipefail -u

# TO_DO: Only thing you need to do is set where you want the decoding to be saved
destination=exp/chain_cleaned_1d/tdnn1d_sp/decode_test

# Set the parameters
decode_nj=8

# Set model and data to be used
decode_graph=exp/tri1/graph
data=data/miami/test

# Get current working directory
cwd=$(pwd)

# Remove Directories from previous runs
rm -rf exp/chain_cleaned_1d/tdnn1d_sp/decode_test
rm -rf exp/chain_cleaned_1d/tdnn1d_sp/decode_test_rescore


echo
echo "===== Starting Decoding ====="
echo

steps/nnet3/decode.sh --num-threads 1 --nj $decode_nj --cmd "$decode_cmd" \
    --acwt 1.0 --post-decode-acwt 10.0 \
    --online-ivector-dir exp/nnet3_cleaned_1d/ivectors_miami/test_hires \
    --scoring-opts "--min-lmwt 5 " \
   exp/chain_cleaned_1d/tdnn1d_sp/graph data/miami/test_hires ${destination} || exit 1;

steps/lmrescore_const_arpa.sh --cmd "$decode_cmd" data/lang_refined data/lang_refined_rescore \
  data/miami/test_hires ${destination} ${destination}_rescore || exit 1

echo
echo "===== Decoding Done ====="
echo "Result saved in: ${cwd}/${destination}_rescore"
exit 0
