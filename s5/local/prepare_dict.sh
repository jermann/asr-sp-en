
#awk '{gsub(/[ˈːˌ]/,"",$2)}1' cmudict-0.7b-ipa.txt > cmudict_clean_1.txt
awk -F'\t' '{sub(/,.*/,"",$2); print}' cmudict-0.7b-ipa.txt > cmudict_one_entry.txt
awk '{gsub(/[ˈːˌ]/,"",$2); gsub(/./,"& ",$2)}1' cmudict_one_entry.txt > cmudict_clean_1.txt

awk '{ $1 = toupper($1) } 1' santiago.txt > santiago_clean_1.txt

cat cmudict_clean_1.txt santiago_clean_1.txt > lexicon.txt
sort -o lexicon.txt lexicon.txt
python3 local/fix_lexicon.py
