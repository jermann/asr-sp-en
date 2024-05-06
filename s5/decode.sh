#!/usr/bin/env bash

# Author: apj2125

# Load Settings
. ./path.sh || exit 1
. ./cmd.sh || exit 1

set -e -o pipefail -u

# TO_DO: Only thing you need to do is set where you want the decoding to be saved
destination=exp/tri1/decode

# Set the parameters
nj=8

# Set model and data to be used
decode_graph=exp/tri1/graph
data=data/miami/test

# Get current working directory
cwd=$(pwd)

echo
echo "===== Starting Decoding ====="
echo

steps/decode.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" "$decode_graph" "$data" "$destination"

echo
echo "===== Decoding Done ====="
echo "Result saved in: $cwd/$desitination"
exit 0
