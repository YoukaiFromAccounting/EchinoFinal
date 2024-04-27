#!/bin/bash

#Run echino_setup.sh script, check for dependencies
echo "Running echino_setup.sh script..."
./echino_setup.sh

#### Read in the URLS and run wget requests from here
#### Save the protein names in an array to access later when calling glycan detection etc. 

#Check if the input file argument is properly provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

#Input file containing URLs
input_file="$1"
#Store all isoforms in array file names to be accessed for subsiquent use
file_names=()

#Check if the input file exists
if [ ! -f "$input_file" ]; then
    echo "Input file not found!"
    exit 1
fi

#Read each line from the file and extract the value after the last equal sign to represent protein name
while IFS= read -r name; do
    #Extract the name of the protein from the URL
    name="$name"
    URL="https://www.ncbi.nlm.nih.gov/sviewer/viewer.fcgi?tool=portal&sendto=on&log$=seqview&db=protein&dopt=fasta&sort=&val="
    file_names+=("$name")
    #run wget request from the url and name the fasta file the protein name extracted from the URL
    wget -O "$name".fasta "$URL$name"
    echo "Downloading fasta file "$name""
done < "$input_file"

###Loop through files and perform glycan detection and ubiquitination detection
echo "FILE NAMES: ${file_names[@]}"
 
#Check if echino_setup.sh script was successful
if [ $? -eq 0 ]; then
	echo "echino_setup.sh script completed successfully."

	cd glycan_detection || exit

	#loop through file names and run glycan detection on each fasta file
	for file in "${file_names[@]}"; do
		#DEBUG
		python3 glycan.py -in ../"$file".fasta -out "" -gap 0
		echo "GLYCAN PREDICTION COMPLETED ON" "$file"
	done

	#Loop through file names and run ubiquitination site detection, save results to file for each fasta file
	#Build SVM model for UbiSite prediction
	cd ..
	echo "Building AAIndex..."
	cd ESA-UbiSite
	cd src/aaindex
	make
	cd ..
	cd ..
	echo "Building LIBSVM model..."
	cd src/libsvm_320
	make
	cd ..
	cd ..
	
	#Run ubiquitination site prediction
	echo "Starting ubiquitination prediction"
	for file in "${file_names[@]}"; do
		mkdir "$file"_output
		perl ESAUbiSite_main.pl ../"$file".fasta "$file"_output
		echo "UBIQUITINATION PREDICTION COMPLETED ON" "$file"
	done
	
	echo "Moving results files..."
	#Create the PTM_Results directory if it doesn't exist
	cd ..
	mkdir -p PTM_Results
	
	#Move the output files from glycan_detection directory to PTM_Results directory
	mv glycan_detection/*_glycans_pos.out PTM_Results/
	
	#Move the fasta_ubicolor files from ESA-UbiSite directories to PTM_Results directory
	mv ESA-UbiSite/*/*.fasta_ubicolor PTM_Results/
	
	#Rename files prior to processing
	echo "Parsing files..."
	directory="PTM_Results"
	for file in "$directory"/*_glycans_pos.out; do
		if [[ $file =~ ([^/]+)_glycans_pos\.out ]]; then
			file_id="${BASH_REMATCH[1]}"
			#echo "BINARY $file_id"
			mv "$file" "$directory/NLG_${file_id}.txt"
		fi
	done
	for file in "$directory"/*.fasta_ubicolor; do
		if [[ $file =~ ([^/]+)\.fasta_ubicolor ]]; then
			file_id="${BASH_REMATCH[1]}"
			mv "$file" "$directory/UBI_${file_id}.txt"
		fi
	done

	echo ""
	echo "Post-Translational Modifications retrieved!"

 	echo "Running ESMFold, retrieving structure files..."
	#Run ESMFold from python calls
	for file in "${file_names[@]}"; do
		python esm_nstart.py "$file.fasta"
	done
	echo "ESMFold predictions completed!" 
	
	#Create RMSD visualizations
	mkdir Prody_Results
	#Run RMSD Generator	
	./rmsd_generator.sh $1

	#Combine all numerical results into results folder
	echo "Aggregating PTM results..."
	python3 results_agg.py
	echo "Script complete! Results available in PTM_results_summary.txt"
else
    echo "Error: echino_setup.sh script failed to complete."
fi
