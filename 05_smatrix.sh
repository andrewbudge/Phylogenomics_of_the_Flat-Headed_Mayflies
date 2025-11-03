#!/bin/bash

mkdir -p "analysis/smatrix"

# Rename first, the concat
for file in data/aligned/*.fasta; do
  sed -i -e "s/Anapos_zebratus/Electrogena_zebrata/g" \
         -e "s/Heptagenia_ngi/Maculogenia_ngi/g" \
         -e "s/Proepeorus_nipponicus/Epeorus_nipponicus/g" \
         -e "s/Cinygmina_furcata/Afronurus_furcata/g" \
         "$file"
done

# use liger to make smx
liger data/aligned/*.fasta data/phylogenomic/DNA12_phylogenomic.fa config/taxa_to_keep.txt \
  > data/final/heptageniidae_smatrix.fas \
  2> data/final/partitions.nex
