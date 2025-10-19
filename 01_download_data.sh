#!/bin/bash

# dec. vars.
OUTPUT_DIR=${1:-"data/raw"}

# make the intital directories for logs, raw data
mkdir -p logs "$OUTPUT_DIR"

echo "Downloading sequences to $OUTPUT_DIR..."

# Use R to scrape all the data from NCBI
Rscript scripts/download_raw_data.R "$OUTPUT_DIR"

# Move mito accessions
mv "$OUTPUT_DIR/mitochondrial_accessions.txt" config/

# Download mito sequences using seqripper
python3 scripts/SeqRipper.py \
    -i config/mitochondrial_accessions.txt \
    -o "$OUTPUT_DIR/" \
    -g 12S 16S COI

# Create master file for all the raw data
cat "$OUTPUT_DIR"/*.fasta > "$OUTPUT_DIR/master_all_raw.fasta"

# Clean up old files
find "$OUTPUT_DIR" -maxdepth 1 -type f -name '*.fasta' ! -name 'master_all_raw.fasta' -delete

echo "Done! Output: $OUTPUT_DIR/master_all_raw.fasta"
