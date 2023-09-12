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
echo "Written by Stacy Christakos"
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

# Read the domains.txt file
echo "[>] Reading domains.txt"
echo
DOMAINS=($(<domains.txt))

# Begin enumerating the domains and output to separate csv files
echo "[!] Starting cybersquatting domain enumeration"
echo
for domain in "${DOMAINS[@]}"; do
  echo "[+] Checking "$domain", please wait..." 
  dnstwist -rmg "$domain" --format csv | column -t > "$domain".csv
  echo "[!] "$domain" enumeration complete!" 
  echo "[>] Please see "$domain".csv for more detail" 
  echo
done

# finish
echo "[>] Cybersquatting domain enumeration complete!"
echo
echo "[>] Filtering the domain enumeration results"
./remove_whitespaces.sh
echo
echo "[>] Filtering complete"

echo "[>] Exiting"