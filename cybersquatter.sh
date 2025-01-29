#!/usr/bin/env bash
#
# CyberSquatter
# By Stacy Christakos
#
# This script automates dnstwist checks against a list of domains,
# optionally against additional TLDs, in parallel, and archives the results.

################################################################################
#                                Configuration                                 #
################################################################################

# Default values (these can be overridden by command-line arguments)
DEFAULT_DOMAINS_FILE="domains.txt"
DEFAULT_TLD_FILE="tld.txt"
DEFAULT_OUTPUT_DIR="archived_results"
DEFAULT_CONCURRENCY=4

################################################################################
#                                Usage Function                                #
################################################################################

usage() {
  echo "Usage: $0 [OPTIONS]"
  echo
  echo "OPTIONS:"
  echo "  -d, --domains <file>       Path to domains file (default: domains.txt)"
  echo "  -t, --tld <file>           Path to TLD file (default: tld.txt)."
  echo "  -o, --output <dir>         Directory to archive results (default: archived_results)"
  echo "  -c, --concurrency <number> Number of parallel jobs (default: 4)"
  echo "  -h, --help                 Show this help message and exit"
  echo
  echo "Description:"
  echo "  This script uses dnstwist to detect typosquatters, phishing attacks,"
  echo "  and brand impersonation for domains listed in a file. Optionally,"
  echo "  you can specify a file of additional TLDs to test for each domain."
  echo "  The script will run enumerations in parallel, then archive results."
  echo
  exit 1
}

################################################################################
#                          Parse Command-Line Args                             #
################################################################################

# Initialize variables with defaults
DOMAINS_FILE="$DEFAULT_DOMAINS_FILE"
TLD_FILE="$DEFAULT_TLD_FILE"
OUTPUT_DIR="$DEFAULT_OUTPUT_DIR"
CONCURRENCY="$DEFAULT_CONCURRENCY"

# Use a while-loop to process arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--domains)
      DOMAINS_FILE="$2"
      shift 2
      ;;
    -t|--tld)
      TLD_FILE="$2"
      shift 2
      ;;
    -o|--output)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -c|--concurrency)
      CONCURRENCY="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "[!] Unknown option: $1"
      usage
      ;;
  esac
done

################################################################################
#                                Banner / Intro                                #
################################################################################

cat << "EOF"
_________        ___.                 _________                    __    __                 
\_   ___ \___.__.\_ |__   ___________/   _____/ ________ _______ _/  |__/  |_  ___________  
/    \  <   |  | | __ \_/ __ \_  __ \_____  \ / ____/  |  \__  \\   __\   __\/ __ \_  __ \ 
\     \___\___  | | \_\ \  ___/|  | \/        < <_|  |  |  // __ \|  |  |  | \  ___/|  | \/ 
 \______  / ____| |___  /\___  >__| /_______  /\__   |____/(____  /__|  |__|  \___  >__|    
        \/\/          \/     \/             \/    |__|          \/                \/        

CyberSquatter can detect typosquatters, phishing attacks, fraud, and brand impersonation.
Useful as an additional source of targeted threat intelligence.
Developed by Stacy Christakos
EOF

echo
echo "[>] This script will run DNSTwist enumerations in parallel."
echo

################################################################################
#                              Pre-Flight Checks                               #
################################################################################

# 1. Check if dnstwist is installed
echo "[>] Checking if dnstwist is installed..."
if ! command -v dnstwist > /dev/null 2>&1; then
  echo "[!] Error: The dnstwist tool is not installed."
  echo "[!] Install via: sudo apt install dnstwist"
  exit 1
else
  echo "[>] dnstwist is installed."
fi

# 2. Check for network connectivity (simple check)
echo "[>] Checking network connectivity..."
if ! ping -c 1 8.8.8.8 &>/dev/null; then
  echo "[!] Warning: Unable to ping 8.8.8.8. Network might be down."
  echo "[!] Continuing might lead to errors. Press Ctrl+C to abort, or wait 5s to continue."
  sleep 5
else
  echo "[>] Network connectivity seems okay."
fi

# 3. Check if domains file exists and is non-empty
echo "[>] Checking domains file: $DOMAINS_FILE"
if [[ ! -f "$DOMAINS_FILE" ]]; then
  echo "[!] Error: Domains file '$DOMAINS_FILE' not found!"
  exit 1
fi
if [[ ! -s "$DOMAINS_FILE" ]]; then
  echo "[!] Error: Domains file '$DOMAINS_FILE' is empty!"
  exit 1
fi

# 4. Optionally check if TLD file exists and is non-empty (we won't exit if missing)
TLD_MODE=false
if [[ -f "$TLD_FILE" && -s "$TLD_FILE" ]]; then
  TLD_MODE=true
  echo "[>] TLD file found: $TLD_FILE"
else
  echo "[!] TLD file '$TLD_FILE' not found or empty. Will NOT run extra TLD permutations."
fi

################################################################################
#                    Prepare a list of domain variants to test                 #
################################################################################

# We'll create a temporary file that lists all domain permutations we want to test.
TEMP_DOMAIN_LIST=$(mktemp)

# Read in the primary domains
mapfile -t DOMAINS < "$DOMAINS_FILE"

if $TLD_MODE; then
  # If TLD_MODE is on, read TLDs
  mapfile -t TLDS < "$TLD_FILE"
  # For each domain, generate domain+TLD pairs if not already fully qualified
  # We also handle the case if the domain *already* includes a TLD (like example.com).
  # We'll just treat them separately for completeness.
  echo "[>] Creating domain permutations with additional TLDs..."
  for domain in "${DOMAINS[@]}"; do
    # We want to strip the existing TLD if present, but only if you want a pure 'root' domain
    # For simplicity, let's keep the original domain as well as add domain with each TLD.

    # Write the original domain
    echo "$domain" >> "$TEMP_DOMAIN_LIST"

    # Optionally add new domain.tld combos
    domain_no_tld="${domain%%.*}"    # naive approach, might strip only the first portion
    for tld in "${TLDS[@]}"; do
      # if domain_no_tld and tld are the same as the original, skip or just include
      echo "${domain_no_tld}.${tld}" >> "$TEMP_DOMAIN_LIST"
    done
  done
else
  # No TLD mode, just enumerate the domains
  for domain in "${DOMAINS[@]}"; do
    echo "$domain" >> "$TEMP_DOMAIN_LIST"
  done
fi

echo "[>] Final list of domains to test is stored in: $TEMP_DOMAIN_LIST"
LINE_COUNT=$(wc -l < "$TEMP_DOMAIN_LIST")
echo "[>] We will test $LINE_COUNT total domains (including TLD expansions)."

################################################################################
#                          Parallel or Serial Execution                        #
################################################################################

# We'll attempt to use GNU parallel if available; otherwise, fallback to xargs
# Note: If you prefer xargs explicitly, remove the parallel check and skip it.

echo "[>] Checking for 'parallel'..."
if command -v parallel > /dev/null 2>&1; then
  echo "[>] 'parallel' found! We'll use $CONCURRENCY parallel jobs."
  echo
  parallel --version
  echo
  # Using parallel: we run each domain in parallel, generating CSV output
  # {} will be replaced by the domain in the list
  cat << "BANNER"
[!] Starting domain enumeration in parallel...
BANNER

  parallel -j "$CONCURRENCY" --colsep '\n' --results /dev/null \
    'dnstwist -rmg {1} --format csv | sed "s/ *, */,/g" > "{1}.csv"; echo "[+] Finished {1}"' \
    :::: "$TEMP_DOMAIN_LIST"

else
  echo "[!] 'parallel' not found. Falling back to 'xargs -P$CONCURRENCY' for parallelization."
  echo
  cat << "BANNER"
[!] Starting domain enumeration in parallel using xargs...
BANNER

  # xargs approach:
  < "$TEMP_DOMAIN_LIST" xargs -I{} -P "$CONCURRENCY" /bin/bash -c \
    'dnstwist -rmg "$1" --format csv | sed "s/ *, */,/g" > "$1.csv"; echo "[+] Finished $1"' _ {}
fi

echo

################################################################################
#                            Archive the CSV Files                             #
################################################################################

# We'll create a time-stamped directory under $OUTPUT_DIR
TIMESTAMP=$(date +%Y-%m-%d)
FINAL_OUTPUT_DIR="${OUTPUT_DIR}/${TIMESTAMP}"

echo "[>] Archiving CSV files..."
if [[ ! -d "$FINAL_OUTPUT_DIR" ]]; then
  echo "[!] Output directory does not exist. Creating now... => $FINAL_OUTPUT_DIR"
  mkdir -p "$FINAL_OUTPUT_DIR"
else
  echo "[!] Output directory already exists: $FINAL_OUTPUT_DIR"
fi

# Move all CSV files to the archive directory
mv ./*.csv "$FINAL_OUTPUT_DIR" 2>/dev/null

echo "[>] CSV files archived to: $FINAL_OUTPUT_DIR"

################################################################################
#                                  Clean Up                                    #
################################################################################

rm -f "$TEMP_DOMAIN_LIST"

echo
echo "[>] Domain enumeration complete!"
echo "[>] Exiting..."
exit 0
