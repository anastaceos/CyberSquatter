#!/bin/bash

echo "_________        ___.                 _________                    __    __                 "
echo "\_   ___ \___.__.\_ |__   ___________/   _____/ ________ _______ _/  |__/  |_  ___________  "
echo "/    \  \<   |  | | __ \_/ __ \_  __ \_____  \ / ____/  |  \__  \\   __\   __\/ __ \_  __ \ "
echo "\     \___\___  | | \_\ \  ___/|  | \/        < <_|  |  |  // __ \|  |  |  | \  ___/|  | \/ "
echo " \______  / ____| |___  /\___  >__| /_______  /\__   |____/(____  /__|  |__|  \___  >__|    "
echo "        \/\/          \/     \/             \/    |__|          \/                \/        "

sleep 2

echo
echo "[*] Reading domains.txt"
domains=domains.txt
echo "[!] Starting cybersquatting domain enumeration"
echo 

for i in `cat $domains`
do
echo "[*] Enumerating $i, please wait..."
dnstwist -rmg "$i" --format csv | column -t > __"$i"__.csv
echo "[!] $i enumeration complete!"
echo "[*] Please see __"$i"__.csv for more detail"
echo
done

echo "[!] Cybersquatting domain enumeration complete!"
echo "[*] Exiting" 