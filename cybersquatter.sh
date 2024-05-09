#!/bin/bash

echo "_________        ___.                 _________                    __    __                 "
echo "\_   ___ \___.__.\_ |__   ___________/   _____/ ________ _______ _/  |__/  |_  ___________  "
echo "/    \  \<   |  | | __ \_/ __ \_  __ \_____  \ / ____/  |  \__  \\   __\   __\/ __ \_  __ \ "
echo "\     \___\___  | | \_\ \  ___/|  | \/        < <_|  |  |  // __ \|  |  |  | \  ___/|  | \/ "
echo " \______  / ____| |___  /\___  >__| /_______  /\__   |____/(____  /__|  |__|  \___  >__|    "
echo "        \/\/          \/     \/             \/    |__|          \/                \/        "
echo "CyberSquatter can detect typosquatters, phishing attacks, fraud, and brand impersonation."
echo "Useful as an additional source of targeted threat intelligence."
echo "CyberSquatter makes use of the dnstwist tool."
echo "Developed by Stacy Christakos"
echo

sleep 2

echo "[>] Checking if dnstwist is installed"
# Check if dnstwist is installed
if ! command -v dnstwist > /dev/null 2>&1; then
    echo "[!] Error: The dnstwist tool is not installed."
    echo "[!] The dnstwist tool is necessary for this script to perform cybersquatting domain enumeration."
    echo "[!] Please install dnstwist by running: sudo apt install dnstwist"
    echo
    exit 1
else
    echo "[>] dnstwist is installed"
    echo
fi

# Check if domains.txt exists
echo "[>] Checking for domains.txt"
if [ -f domains.txt ]; then
  echo "[>] domains.txt found"
  if [ -s domains.txt ]; then
    echo "[>] domains.txt contains data"
  else
    echo "[!] Error: domains.txt is empty"
    exit 1
  fi
else  
  echo "[!] Error: domains.txt not found"
  exit 1
fi

# Check if tld.txt exists
echo "[>] Checking for tld.txt"
if [ -f tld.txt ]; then
  echo "[>] tld.txt found"
  if [ -s tld.txt ]; then
    echo "[>] tld.txt contains data"
  else
    echo "[!] Error: tld.txt is empty"
    exit 1
  fi
else  
  echo "[!] Error: tld.txt not found"
  exit 1
fi

# Read the domains.txt file
echo "[>] Reading domains.txt and tld.txt"
echo
DOMAINS=($(<domains.txt))

# Begin enumerating the domains and output to separate csv files
echo "[!] Starting cybersquatting domain enumeration"
echo
for domain in "${DOMAINS[@]}"; do
  echo "[+] Checking "$domain", please wait..." 
  dnstwist -rmg "$domain" --tld tld.txt --format csv | sed 's/ *, */,/g' > "$domain".csv
  echo "[!] "$domain" enumeration complete!" 
  echo "[>] Please see "$domain".csv for more detail" 
  echo
done

# Define the output directory with the current date
output_dir="archived_results/$(date +%Y-%m-%d)"

# Function to archive and clean up CSV files
archive_csv_files() {
  echo "[>] Archiving CSV files..."
  # Check if the output directory already exists
  if [ ! -d "$output_dir" ]; then
    echo "[!] Output directory does not exist. Creating now..."
    mkdir -p "$output_dir"
  else
    echo "[!] Output directory already exists."
  fi
  # Move all CSV files to the output directory
  mv *.csv "$output_dir"
  echo "[>] CSV files archived in directory: $output_dir"
}

# execute csv archiving
echo "[>] Executing CSV archiving"
archive_csv_files
echo

# finish
echo "[>] Cybersquatting domain enumeration complete!"
echo "[>] Exiting"