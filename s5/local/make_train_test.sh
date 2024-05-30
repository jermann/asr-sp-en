# Author: apj2125

# makes a dev set
# utils/copy_data_dir.sh data/miami/bangortalk data/miami/bangortalk_full

# makes a random list of items
perl utils/shuffle_list.pl data/miami/bangortalk/segments > shuffled_list
head -37814 shuffled_list > shuffled_train
tail -2000 shuffled_list > shuffled_test

# splits data intro training and validation/testing sets
utils/subset_data_dir.sh --utt-list shuffled_train data/miami/bangortalk data/miami/train
utils/subset_data_dir.sh --utt-list shuffled_test data/miami/bangortalk data/miami/test

# removes temp lists
rm shuffled_list shuffled_train shuffled_test

# Remove Segments File

# Adding Absolute Path to Wav.scp
# awk 'BEGIN { FS="\t" } { $2 = "/home/apj2125/kaldi-trunk/egs/asr-sp-en/s5/data/miami/" $2 } 1' wav.scp > wav_absolute.scp

# # splits non-training data into validation and testing
# utils/subset_data_dir.sh --first data/${trans_type}_deveval 20 data/${dev_set}
# utils/subset_data_dir.sh --last data/${trans_type}_deveval 20 data/${eval_set}

utils/subset_data_dir.sh --utt-list shuffled_train data/miami/test_hires data/miami/test_hires_decode