#!/bin/bash
# relabel_sequences.sh

if [ $# -ne 3 ]; then
    echo "Usage: $0 <input_dir> <output_dir> <taxa_list.txt>"
    echo "Example: $0 data/aligned/ data/relabeled/ config/Master_Taxa_Names.txt"
    exit 1
fi

INPUT_DIR=$1
OUTPUT_DIR=$2
TAXA_LIST=$3

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Process each fasta file
for fasta in "$INPUT_DIR"/*.fasta "$INPUT_DIR"/*.fa; do
    [ -f "$fasta" ] || continue
    
    basename=$(basename "$fasta" .fasta)
    basename=$(basename "$basename" .fa)
    
    output_fasta="$OUTPUT_DIR/${basename}_relabeled.fasta"
    key_file="$OUTPUT_DIR/${basename}_label_key.txt"
    
    awk -v taxa_file="$TAXA_LIST" -v key_out="$key_file" '
    BEGIN {
        # Load valid taxa into array
        while ((getline line < taxa_file) > 0) {
            taxa[line] = 1
        }
        close(taxa_file)
        
        # Print key file header
        print "Accession\tTaxon\tRelabeled_As\tDescription" > key_out
    }
    
    /^>/ {
        # Extract accession (first field after >)
        accession = $1
        gsub(/^>/, "", accession)
        
        # Extract taxon name
        # Check for three-word patterns first
        if ($3 == "sp." && $4 ~ /^EP[0-9]+$/) {
            # Pattern: Genus sp. EPxxx
            taxon = $2 " " $3 " " $4
        } else if ($4 ~ /^EP[0-9]+$/) {
            # Pattern: Genus species EPxxx
            taxon = $2 " " $3 " " $4
        } else {
            # Pattern: Genus species
            taxon = $2 " " $3
        }
        
        # Store original description
        description = substr($0, 2)  # Everything after >
        
        # Check if taxon is valid
        if (taxon in taxa) {
            # Create relabeled name (replace spaces with underscores)
            relabeled = taxon
            gsub(/ /, "_", relabeled)
            
            print ">" relabeled
            
            # Write to key file
            print accession "\t" taxon "\t" relabeled "\t" description > key_out
        } else {
            # Taxon not in list - flag it
            print ">" taxon "_[NOT_IN_LIST]"
            print accession "\t" taxon "\t[SKIPPED]" "\t" description > key_out
        }
        
        next
    }
    
    # Print sequence lines as-is
    {
        print
    }
    ' "$fasta" > "$output_fasta"
    
    echo "Processed: $basename"
done

echo ""
echo "Relabeling complete!"
echo "Files written to: $OUTPUT_DIR/"
echo ""
echo "Checking for issues..."

# Check for any sequences that weren't in the taxa list
grep "NOT_IN_LIST" "$OUTPUT_DIR"/*.txt 2>/dev/null | wc -l | xargs -I {} echo "Sequences not in taxa list: {}"

# Check for duplicate labels within files
echo "Checking for duplicate labels within files..."
for file in "$OUTPUT_DIR"/*.fasta; do
    [ -f "$file" ] || continue
    dups=$(grep ">" "$file" | sort | uniq -d)
    if [ ! -z "$dups" ]; then
        echo "DUPLICATES in $(basename $file):"
        echo "$dups"
    fi
done
