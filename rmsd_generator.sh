#!/bin/bash

#Check if the input file argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

#Input file containing URLs (Eg: isoforms.txt)
input_file="$1"
#Store all isoforms in array file names to be accessed for subsiquent use
file_names=()

#Read each line from the file and extract the value after the last equal sign to represent protein name
while IFS= read -r url; do
    #Extract the name of the protein from the URL
    URL="$url"
    name=$(echo "$url" | grep -oE '[^=]+$')
    file_names+=("$name")
done < "$input_file"

#Loop over PDB results combinations
for file1 in "${file_names[@]}"; do
    echo "$file1"
    for file2 in "${file_names[@]}"; do
        echo "$file2"
        if [ "$file1" != "$file2" ]
        then
            echo Running rmsd analysis on "$file1" and "$file2"
            python3 rmsd_plot.py "$file1.pdb" "$file2.pdb"
        fi
    done
done
