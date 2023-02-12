#!/bin/bash

printf "_________        ___.                 _________                    __    __                 \n"
printf "\_   ___ \___.__.\_ |__   ___________/   _____/ ________ _______ _/  |__/  |_  ___________  \n"
printf "/    \  \<   |  | | __ \_/ __ \_  __ \_____  \ / ____/  |  \__  \\   __\   __\/ __ \_  __ \ \n"
printf "\     \___\___  | | \_\ \  ___/|  | \/        < <_|  |  |  // __ \|  |  |  | \  ___/|  | \/ \n"
printf " \______  / ____| |___  /\___  >__| /_______  /\__   |____/(____  /__|  |__|  \___  >__|    \n"
printf "        \/\/          \/     \/             \/    |__|          \/                \/        \n"
printf "CyberSquatter can detect typosquatters, phishing attacks, fraud, and brand impersonation.\n"
printf "Useful as an additional source of targeted threat intelligence.\n"
printf "CyberSquatter makes use of the dnstwist tool.\n\n"

sleep 2

printf "[*] Checking if dnstwist is installed\n"
# Check if dnstwist is installed
if ! command -v dnstwist > /dev/null 2>&1; then
    printf "[!] Error: The dnstwist tool is not installed.\n"
    printf "[!] The dnstwist tool is necessary for this script to perform cybersquatting domain enumeration.\n"
    printf "[-] Please install dnstwist by running: sudo apt install dnstwist\n"
    exit 1
else
    printf "[*] dnstwist is installed\n\n"
fi

printf "[*] Checking for domains.txt\n"
# Check if domains.txt exists
if [ ! -f domains.txt ]; then
    printf "[!] Error: domains.txt not found\n"
    exit 1
else  
    printf "[*] domains.txt found\n"
fi

# Check if domains.txt contains data
if [ ! -s domains.txt ]; then
    printf "[!] Error: domains.txt is empty\n"
    exit 1
else
    printf "[*] domains.txt contains data\n"
fi

# Read the domains.txt file
printf "[*] Reading domains.txt\n\n"
domains=($(<domains.txt))

# Begin enumerating the domains and output to separate csv files
printf "[!] Starting cybersquatting domain enumeration\n"
for i in "${domains[@]}"; do
  printf "[*] Enumerating %s, please wait...\n" "$i"
  dnstwist -rmg "$i" --format csv | column -t > __"$i"__.csv
  printf "[!] %s enumeration complete!\n" "$i"
  printf "[*] Please see __%s__.csv for more detail\n\n" "$i"
done

# finish
printf "[!] Cybersquatting domain enumeration complete!\n"
printf "[*] Exiting\n"