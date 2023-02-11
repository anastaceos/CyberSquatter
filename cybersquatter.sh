#!/bin/bash

echo "_________        ___.                 _________                    __    __                 "
echo "\_   ___ \___.__.\_ |__   ___________/   _____/ ________ _______ _/  |__/  |_  ___________  "
echo "/    \  \<   |  | | __ \_/ __ \_  __ \_____  \ / ____/  |  \__  \\   __\   __\/ __ \_  __ \ "
echo "\     \___\___  | | \_\ \  ___/|  | \/        < <_|  |  |  // __ \|  |  |  | \  ___/|  | \/ "
echo " \______  / ____| |___  /\___  >__| /_______  /\__   |____/(____  /__|  |__|  \___  >__|    "
echo "        \/\/          \/     \/             \/    |__|          \/                \/        "

sleep 2

# Check if dnstwist is installed
if ! command -v dnstwist > /dev/null 2>&1; then
    echo "Error: dnstwist tool is not installed."
    echo "Please install dnstwist before proceeding"
    echo "sudo apt install dnstwist"
    exit 1
fi

# Read the domains.txt file
echo 
echo "[*] Reading domains.txt"
domains=domains.txt
echo 

# Begin enumerating the domains and output to separate csv files
echo "[!] Starting cybersquatting domain enumeration"
for i in `cat $domains`
do
echo "[*] Enumerating $i, please wait..."
dnstwist -rmg "$i" --format csv | column -t > __"$i"__.csv
echo "[!] $i enumeration complete!"
echo "[*] Please see __"$i"__.csv for more detail"
echo
done

# finish
echo "[!] Cybersquatting domain enumeration complete!"
echo "[*] Exiting" 