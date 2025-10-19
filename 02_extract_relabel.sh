#!/bin/bash

INPUT_FASTA=$1
OUTPUT_DIR=$2

echo "Extracting and relabeling genes..."

# Use temp dir. for parsed files
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Step 1: Parse genes and filter to longest per taxon
bash scripts/filter_longest_per_taxon_by_gene.sh \
    "$INPUT_FASTA" \
    config/master_taxa_names.txt \
    config/locus_search_terms.txt \
    "$TEMP_DIR/"

# This is a quick and dirty fix to remove a non-homologous seq.
if [ -f "$TEMP_DIR/H3.fasta" ]; then
    seqkit grep -v -p "LC513125.1" "$TEMP_DIR/H3.fasta" > "$TEMP_DIR/H3_clean.fasta"
    mv "$TEMP_DIR/H3_clean.fasta" "$TEMP_DIR/H3.fasta"
fi

# Relabel seqs
mkdir -p "$OUTPUT_DIR" 
bash scripts/relabel_seqs.sh \
    "$TEMP_DIR/" \
    "$OUTPUT_DIR/" \
    config/master_taxa_names.txt

# Move label keys to logs
mv "$OUTPUT_DIR"/*.txt logs/ 2>/dev/null || true

echo "Done! Relabeled sequences in: $OUTPUT_DIR/"
