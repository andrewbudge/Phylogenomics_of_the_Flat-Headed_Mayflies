# Phylogenomics_of_the_Flat-Headed_Mayflies
Automated pipeline for phylogenetic analysis of Heptageniidae using multi-locus sequence data from GenBank.

**Target genes**: 12S, 16S, 18S, 28S, COI, H3

## Pipeline Steps

### 1. Download Data (`01_download_data.sh`)

Downloads all Heptageniidae sequences from GenBank using R/rentrez. Complete mitochondrial genomes are processed with [SeqRipper](https://github.com/andrewbudge/SeqRipper) to extract specific genes (12S, 16S, COI). All sequences are combined into `master_all_raw.fasta`.

### 2. Extract and Relabel (`02_extract_relabel.sh`)

Extracts target genes from raw data and filters to keep only the longest sequence per taxon per locus. Headers are reformatted to genus and species names only. Known problematic sequences are removed.

### 3. Filter Taxa (`03_filter.sh`)

Retains only taxa represented in at least 3 gene files to ensure adequate data coverage for phylogenetic inference.

### 4. Align and Trim (`04_align_trm.sh`)

Sequences are aligned with MAFFT (`--auto`) and trimmed with ClipKIT (`smart-gap`) to remove poorly aligned regions while retaining phylogenetically informative sites.

### 5. Build Supermatrix (`05_smatrix.sh`)

Creates a concatenated supermatrix from all aligned genes using FASconCAT. Taxonomic names are standardized to handle synonyms and reclassifications.

### 6. Maximum-Likelihood Analysis (`06_ML_analysis.sh`)

Runs IQ-TREE 3 analyses on three datasets:

- **Supermatrix**: Mixed models (MIX+MFP) with 1000 bootstrap replicates
- **Phylogenomic DNA12**: Mixed models for codon-partitioned data
- **Phylogenomic AA**: Single model for amino acid data

## Usage

Run the complete pipeline:

```bash
bash pipeline.sh
```

Or run individual steps:

```bash
bash scripts/01_download_data.sh
bash scripts/02_extract_relabel.sh data/raw/master_all_raw.fasta data/aligned
bash scripts/03_filter.sh data/aligned/ data/phylogenomic/DNA12_phylogenomic.fa
bash scripts/04_align_trm.sh data/aligned/ data/aligned/
bash scripts/05_smatrix.sh data/aligned/ data/final data/phylogenomic/DNA12_phylogenomic.fa
bash scripts/06_ML_analysis.sh
```

## Requirements

- R with `rentrez`
- Python 3
- MAFFT
- SeqKit
- FASconCAT-G
- IQ-TREE 3

## Output

- `data/final/heptageniidae_smatrix.fas` - Final supermatrix
- `analysis/smatrix/` - Supermatrix ML results
- `analysis/phylo_DNA12/` - DNA12 ML results
- `analysis/phylo_AA/` - AA ML results
