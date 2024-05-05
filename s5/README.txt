UNI: apj2125
Name: Alexander Jermann

Date: 5/5/2024

Project Title: Spanglish Code-Switched Speech Recognition

Project Summary (Abstract): Code switching (CS) refers to the practice of
alternating between two or more languages in speech or text. While
code-switching is a very common practice among bilingual or multilingual people,
code-switched speech datasets are rare and too small to train an acoustic model
from scratch. In this paper, we propose an Automatic Speech Recognition (ASR)
system for improved performance on Spanish and English code-switched speech.
To this end we use the Miami Bangor transcribed speech dataset to train an
Acoustic model. For the language model we use a code-switched Dataset from
Twitter as well as monolingual Spanish and English text datasets to train and
fine-tune the language model. We propose a multilingual architecture that merges
all the graphemes using 3-grams trained on the transcription data. In the
decoding step we supplement the data with Part of Speech (POS) tags to help the
model learn switch points that are more likely to occur in natural code-switched
speech.

Required Tools:
- Python3
  Pip
    - convertextract

To Run code:
- run.sh: Run's training. Please note that this deletes files and re-starts a
2 day process.
- test.sh


Documenting Contributions:
Each file has a comment to denote major modifications with my UNI apj2125.
Please note that if I only changed the folder source or destination in a
command I am not counting this as a change.


Modified files
- run.sh
  - stage 0: Self-written
  - stages 1-3 & 9-17: adapted from egs/tedlium/r5_s3/run.sh
  - stages
- local/chain/tuning/run_tdnn_1d.sh
  - changed architecture
  - changed training to us NVIDIA smi -c 3
- local/nnet3/run_ivector_common_no_hires.sh
- local/nnet3/run_ivector_common.sh

Created files
- local/append_mono.py : this file converts stereo wav files to mono wav files
