import os
import re

def extract_numbers_from_file(file_path):
    # Open the text file
    with open(file_path, "r") as file:
        data = file.read()

    # Use regular expression to extract whole numbers from the text
    numbers = [int(num) for num in re.findall(r'(?<!\.)\b([2-9]|[1-9]\d+)\b', data)]

    # Remove duplicates by converting the list to a set and then back to a list
    numbers = sorted(set(numbers))

    # Return the extracted numbers
    return numbers
    
def extract_decimals_from_file(file_path):
    # Open the text file
    with open(file_path, "r") as file:
        # Read the first line
        first_line = file.readline().strip()

        # Return the extracted decimals
        return first_line


# Directory containing the files
directory = "PTM_Results"

# Initialize dictionaries to store data
nlg_data = {}
ubi_data = {}
mean_factor = {}


# Iterate over files in the directory
for file_name in os.listdir(directory):
    if file_name.startswith("NLG"):
        # Extract ID from file name
        id_ = "_".join(file_name.split("_")[1:])
        id_ = id_[:-4]
        # Extract numbers from file and store in dictionary
        nlg_data[id_] = extract_numbers_from_file(os.path.join(directory, file_name))
    elif file_name.startswith("UBI"):
        # Extract ID from file name
        id_ = "_".join(file_name.split("_")[1:])
        id_ = id_[:-4]
        # Extract numbers from file and store in dictionary
        ubi_data[id_] = extract_numbers_from_file(os.path.join(directory, file_name))
    else:
        id_ = file_name[:-4]
        print("ID is", id_)
       	decimal = extract_decimals_from_file(os.path.join(directory, file_name))
        mean_factor[id_] = decimal
        print("DECIMAL IS", mean_factor[id_])
# Write data to text file
with open("PTM_results_summary.txt", "w") as txtfile:
    # Write header
    txtfile.write("ID\tN-Linked Glycosylation Sites\tUbiquitination Sites\tpLDDT Score\n")
    
    # Iterate over IDs and write data to file
    for id_ in sorted(set(nlg_data.keys()) | set(ubi_data.keys())):
        # Get values from dictionaries
        nlg_sites = ','.join(map(str, nlg_data.get(id_, [])))
        ubi_sites = ','.join(map(str, ubi_data.get(id_, [])))
        plddt_score = mean_factor.get(id_, "")  # Get the pLDDT score
        print("PLDDT SCORE IS", plddt_score)
        
        # Write data to file
        txtfile.write(f"{id_}\t{nlg_sites}\t{ubi_sites}\t{plddt_score}\n")