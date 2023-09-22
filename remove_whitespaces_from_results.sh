#!/bin/bash

# Check if the script received a file argument
if [ "$#" -ne 1 ]; then
  echo "[>] Usage: $0 <filename.csv>"
  exit 1
fi

# Get the file from the argument
file="$1"

# Check if the provided argument is a valid CSV file
if [ ! -f "$file" ] || [[ ! "$file" == *.csv ]]; then
  echo "[!] Error: Please provide a valid CSV file."
  exit 1
fi

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
echo "[>] Finished processing the CSV file."
