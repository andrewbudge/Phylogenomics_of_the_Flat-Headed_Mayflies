#!/bin/bash

DATA_DIR=$1
PHYLO_REF=$2

# This make a list of all taxa that have at 3 genes (appear in at least 3 of the files)
{
    for file in "$DATA_DIR"/*_relabeled.fasta; do
        grep ">" "$file" | sed 's/>//'
    done
    grep ">" "$PHYLO_REF" | sed 's/>//'
} | sort | uniq -c | awk '$1 >= 3 {print $2}' > config/taxa_to_keep.txt


# Filter fastas to keep only adquatly represented taxa
for file in "$DATA_DIR"/*_relabeled.fasta; do
    [ -f "$file" ] || continue
    
    gene=$(basename "$file" _relabeled.fasta)
    temp=$(mktemp)
    
    seqkit grep -f config/taxa_to_keep.txt "$file" > "$temp"
    mv "$temp" "$file"
done
