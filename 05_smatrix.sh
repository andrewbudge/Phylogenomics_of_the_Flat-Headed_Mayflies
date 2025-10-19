#!/bin/bash

ALIGNED_DIR=$1
OUTPUT_DIR=$2
PHYLO_FILE=$3

mkdir -p "$OUTPUT_DIR"

# This is a horrible solution but it works and that is what matters
sed <(seqkit concat -f -F "N" "$ALIGNED_DIR"/*.fasta) \
  -e "s/Anapos_zebratus/Electrogena_zebrata/g" \
  -e "s/Heptagenia_ngi/Maculogenia_ngi/g" \
  -e "s/Proepeorus_nipponicus/Epeorus_nipponicus/g" \
  -e "s/Cinygmina_furcata/Afronurus_furcata/g" \
  > "$OUTPUT_DIR/six_gene_smatrix.fas"

# make tmp phylo file
cp "$PHYLO_FILE" "$OUTPUT_DIR/tmp_DNA12_phylo.fas"

# Create smatrix
cd "$OUTPUT_DIR"
perl "$OLDPWD/scripts/FASconCAT_v1.11.pl" -s

# Rename files
mv FcC_info.xls smatrix_info.xls
mv FcC_smatrix.fas heptageniidae_smatrix.fas

# Clean up
rm tmp_DNA12_phylo.fas

cd "$OLDPWD"
