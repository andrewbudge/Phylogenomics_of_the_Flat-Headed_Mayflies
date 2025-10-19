#!/bin/bash
# filter_longest_per_taxon_by_gene.sh

if [ $# -ne 4 ]; then
    echo "Usage: $0 <input.fasta> <taxa_list.txt> <locus_config.txt> <output_prefix>"
    echo "Example: $0 input.fasta config/Master_Taxa_Names.txt config/locus_search_terms.txt filtered_"
    echo "  Will create: filtered_12S.fasta, filtered_COI.fasta, etc."
    exit 1
fi

FASTA=$1
TAXA_LIST=$2
LOCUS_CONFIG=$3
OUTPUT_PREFIX=$4

awk -v taxa_file="$TAXA_LIST" -v locus_file="$LOCUS_CONFIG" -v prefix="$OUTPUT_PREFIX" '
BEGIN {
    # Load taxa list
    while ((getline line < taxa_file) > 0) {
        taxa[line] = 1
    }
    close(taxa_file)
    
    # Load locus search terms
    while ((getline line < locus_file) > 0) {
        split(line, fields, "\t")
        gene_name = fields[1]
        
        # Parse short patterns (column 2)
        split(fields[2], short_patterns, ";")
        for (i in short_patterns) {
            patterns[short_patterns[i]] = gene_name
        }
        
        # Parse long patterns (column 3)
        split(fields[3], long_patterns, ";")
        for (i in long_patterns) {
            patterns[long_patterns[i]] = gene_name
        }
        
        # Track which genes we are looking for
        gene_list[gene_name] = 1
    }
    close(locus_file)
}

/^>/ {
    # Save previous sequence if it was a keeper
    if (keep_current && taxon != "" && gene != "") {
        len = length(seq)
        key = taxon "|||" gene
        
        if (!(key in max_len) || len > max_len[key]) {
            max_len[key] = len
            headers[key] = current_header
            sequences[key] = seq
            genes[key] = gene
            taxons[key] = taxon
        }
    }
    
    # Parse new header
    current_header = substr($0, 2)  # Remove ">"
    full_header = $0
    
    # Extract taxon name (handle "Genus species" and "Genus sp. CODE")
    if ($3 == "sp." && $4 != "") {
        taxon = $2 " " $3 " " $4
    } else {
        taxon = $2 " " $3
    }
    
    # Detect gene type by checking all patterns
    gene = ""
    for (pattern in patterns) {
        if (index(full_header, pattern) > 0) {
            # Skip if it is a pseudogene
            if (index(full_header, "pseudogene") == 0) {
                gene = patterns[pattern]
                break
            }
        }
    }
    
    # Check if this taxon is in our list AND gene was detected
    keep_current = ((taxon in taxa) && gene != "")
    seq = ""
    next
}

{
    # Accumulate sequence lines
    if (keep_current) {
        seq = seq $0
    }
}

END {
    # Process last sequence
    if (keep_current && taxon != "" && gene != "") {
        len = length(seq)
        key = taxon "|||" gene
        
        if (!(key in max_len) || len > max_len[key]) {
            max_len[key] = len
            headers[key] = current_header
            sequences[key] = seq
            genes[key] = gene
            taxons[key] = taxon
        }
    }
    
    # Initialize counters for each gene
    for (g in gene_list) {
        gene_counts[g] = 0
    }
    
    # Output to separate files by gene
    for (k in headers) {
        g = genes[k]
        output_file = prefix g ".fasta"
        print ">" headers[k] > output_file
        print sequences[k] > output_file
        gene_counts[g]++
    }
    
    # Print summary
    print "Filtering complete!" > "/dev/stderr"
    print "" > "/dev/stderr"
    for (g in gene_list) {
        if (g in gene_counts && gene_counts[g] > 0) {
            print g ": " gene_counts[g] " sequences -> " prefix g ".fasta" > "/dev/stderr"
        } else {
            print g ": 0 sequences (no output file created)" > "/dev/stderr"
        }
    }
}
' "$FASTA"

echo ""
echo "Input total sequences: $(grep -c "^>" "$FASTA")"
