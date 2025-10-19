#!/bin/bash

# Download all raw data from genbank (NCBI)
scripts/01_download_data.sh

# extract wanted genes and relabel fasta names.
bash scripts/02_extract_relabel.sh data/raw/master_all_raw.fasta data/aligned

# filter taxa so that we only keep taxa that have at least three genes
bash scripts/03_filter.sh data/aligned/ data/phylogenomic/DNA12_phylogenomic.fa

# Perform alignment and trimming of seq data
bash scripts/04_align_trm.sh data/aligned/ data/aligned/

# Create supermatrix
bash scripts/05_smatrix.sh data/aligned/ data/final data/phylogenomic/DNA12_phylogenomic.fa
