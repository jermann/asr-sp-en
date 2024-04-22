# makes a dev set
# utils/copy_data_dir.sh data/miami/bangortalk data/miami/bangortalk_full

# makes a random list of items
perl utils/shuffle_list.pl data/miami/bangortalk/text > shuffled_list
head -40506 shuffled_list > shuffled_train
tail -4500 shuffled_list > shuffled_test

# splits data intro training and validation/testing sets
utils/subset_data_dir.sh --utt-list shuffled_train data/miami/bangortalk data/miami/train
utils/subset_data_dir.sh --utt-list shuffled_test data/miami/bangortalk data/miami/test

# removes temp lists
rm shuffled_list shuffled_train shuffled_test

# # splits non-training data into validation and testing
# utils/subset_data_dir.sh --first data/${trans_type}_deveval 20 data/${dev_set}
# utils/subset_data_dir.sh --last data/${trans_type}_deveval 20 data/${eval_set}
