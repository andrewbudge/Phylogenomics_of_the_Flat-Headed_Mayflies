#!/bin/bash

INPUT_DIR=$1
OUTPUT_DIR=$2

mkdir -p "$OUTPUT_DIR"

# Perform alignment
for file in "$INPUT_DIR"/*_relabeled.fasta; do
    basename=$(basename "$file" _relabeled.fasta)
    mafft --thread 6 --auto "$file" > "$OUTPUT_DIR/${basename}_tmp.fasta"
done


# trim alignments using clipkit
python3 -m venv clipkitENV
source clipkitENV/bin/activate
pip install clipkit

for file in "$OUTPUT_DIR"/*_tmp.fasta; do
    basename=$(basename "$file" _tmp.fasta)
    clipkit "$file" -m smart-gap -o "$OUTPUT_DIR/${basename}_aln.fasta"
    rm "$file"  # Remove temp alignment
done

deactivate
rm -rf clipkitENV/

# Remove relabeled files
rm "$INPUT_DIR"/*_relabeled.fasta
