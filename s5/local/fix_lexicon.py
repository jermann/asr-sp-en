# Open the input file
with open('lexicon.txt', 'r') as f:
    # Read all lines from the file
    lines = f.readlines()

# Filter out the empty lines
non_empty_lines = [line.strip() for line in lines if line.strip()]

# Write the non-empty lines to a new file
with open('lexicon_clean.txt', 'w') as f:
    f.write('\n'.join(non_empty_lines))
