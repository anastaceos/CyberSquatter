#!/bin/bash

# Specify the directory containing the CSV files
#directory="CyberSquatter"

# Iterate through each CSV file in the directory
#for file in "$directory"/*.csv; do
for file in *.csv; do
  # Create a temporary file for the modified content
  temp_file=$(mktemp)

  # Read each line of the CSV file
  while IFS= read -r line; do
    # Remove leading and trailing white spaces from each field
    modified_line=$(echo "$line" | awk -F',' 'BEGIN{OFS=","} {for(i=1; i<=NF; i++) gsub(/^[[:space:]]+|[[:space:]]+$/,"",$i); gsub(/[[:space:]]+/," ",$0)}1')

    # Append the modified line to the temporary file
    echo "$modified_line" >> "$temp_file"
  done < "$file"

  # Replace the original file with the modified content
  mv "$temp_file" "$file"

  echo "[!] Processed: $file"
done

echo
echo "[>] Finished processing all CSV files."

