library(rentrez)

# Config
args <- commandArgs(trailingOnly = TRUE)
output_dir <- ifelse(length(args) > 0, args[1], "data/raw")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
dir.create("logs", showWarnings = FALSE, recursive = TRUE)

# Taxa list
taxa_list <- list(
  "Heptageniidae" = "txid178295[Organism]",
  "Arthroplea_bipunctata" = "txid309667[Organism]",
  "Pseudiron_centralis" = "txid243528[Organism]",
  "Siphloplecton_interlineatum" = "txid309631[Organism]",
  "Metretopus_borealis" = "txid219465[Organism]",
  "Oligoneuriella_pallida" = "txid1928497[Organism]",
  "Analetris_eximia" = "txid240917[Organism]",
  "Isonychia_sp" = "txid650555[Organism]"
)

# Download function
download_taxon <- function(taxon_id, taxon_name) {
  # Non-mitochondrial sequences
  regular_term <- paste(taxon_id, 
                       'NOT (mitochondrion[Title] AND complete[Title] AND 13000:20000[Sequence Length])')
  regular <- entrez_search(db = 'nuccore', term = regular_term, use_history = TRUE)
  
  sequences <- ""
  if (regular$count > 0) {
    sequences <- entrez_fetch(db = 'nuccore', web_history = regular$web_history,
                             rettype = 'fasta', retmax = 10000)
  }
  
  # Complete mitochondrial genomes
  mito_term <- paste(taxon_id, 
                    'AND mitochondrion[Title] AND complete[Title] AND 13000:20000[Sequence Length]')
  mito <- entrez_search(db = 'nuccore', term = mito_term, retmax = 10000)
  
  mito_accessions <- character(0)
  if (mito$count > 0) {
    summaries <- entrez_summary(db = 'nuccore', id = mito$ids)
    mito_accessions <- sapply(summaries, function(x) x$accessionversion)
  }
  
  Sys.sleep(0.5)
  
  return(list(
    sequences = sequences,
    mito_accessions = mito_accessions,
    regular_count = regular$count,
    mito_count = mito$count
  ))
}

# Main loop
cat("Downloading sequences for", length(taxa_list), "taxa...")

all_sequences <- list()
all_mito_accessions <- character(0)
summary_rows <- list()

for (i in seq_along(taxa_list)) {
  result <- download_taxon(taxa_list[[i]], names(taxa_list)[i])
  
  if (nchar(result$sequences) > 0) {
    all_sequences[[i]] <- result$sequences
  }
  
  all_mito_accessions <- c(all_mito_accessions, result$mito_accessions)
  
  summary_rows[[i]] <- data.frame(
    Taxon = names(taxa_list)[i],
    Regular_Seqs = result$regular_count,
    Mito_Genomes = result$mito_count,
    stringsAsFactors = FALSE
  )
}

# Save results
writeLines(paste(all_sequences, collapse = "\n"), 
          file.path(output_dir, "all_taxa_sequences.fasta"))
writeLines(all_mito_accessions, 
          file.path(output_dir, "mitochondrial_accessions.txt"))

summary_df <- do.call(rbind, summary_rows)
summary_df$Date <- Sys.Date()
write.csv(summary_df, "logs/download_summary.csv", row.names = FALSE)

cat(" Done!\n")
