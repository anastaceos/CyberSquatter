#!/usr/bin/env bash
#
# Domain Sentinel: A Tool to Detect Typosquatting, Phishing, and Fraud
# By Stacy Christakos
#
# This script:
#   - Requires a domains file (-d).
#   - Optionally takes a TLD file (-t). If provided, expansions are generated.
#   - Can run in either serial or parallel mode.
#   - Archives CSV outputs to a dated folder under --output.
#

################################################################################
#                              Default Settings                                #
################################################################################

DEFAULT_DOMAINS_FILE=""     # No default: must pass -d
DEFAULT_TLD_FILE=""         # No default TLD file (only used if specified)
DEFAULT_OUTPUT_DIR="archived_results"
DEFAULT_MODE="serial"       # can be 'serial' or 'parallel'
DEFAULT_CONCURRENCY=2

################################################################################
#                                Usage Function                                #
################################################################################

usage() {


  echo "     ____                        _          "  
  echo "    / __ \____  ____ ___  ____ _(_)___      "
  echo "   / / / / __ \/ __ `__ \/ __ `/ / __ \     "
  echo "  / /_/ / /_/ / / / / / / /_/ / / / / /     "
  echo " /_____/\____/_/ /_/ /_/\__,_/_/_/ /_/__    "
  echo "   / ___/___  ____  / /_(_)___  ___  / /    "
  echo "   \__ \/ _ \/ __ \/ __/ / __ \/ _ \/ /     "
  echo "  ___/ /  __/ / / / /_/ / / / /  __/ /      "
  echo " /____/\___/_/ /_/\__/_/_/ /_/\___/_/       "                                          
  echo ""
  echo "A Tool to Detect Typosquatting, Phishing, and Fraud"

  echo "Usage: $0 [OPTIONS]"
  echo
  echo "OPTIONS:"
  echo "  -d, --domains <file>         Path to the REQUIRED domains file"
  echo "  -t, --tld <file>             Path to an OPTIONAL TLD file (no default)"
  echo "  -o, --output <dir>           Directory to archive results (default: $DEFAULT_OUTPUT_DIR)"
  echo "  -m, --mode <serial|parallel> Execution mode (default: $DEFAULT_MODE)"
  echo "  -c, --concurrency <number>   Number of parallel jobs (default: $DEFAULT_CONCURRENCY)"
  echo "  -h, --help                   Show this help message and exit"
  echo
  echo "Examples:"
  echo "  $0 -d domains.txt                    # Serial mode, no TLD expansions"
  echo "  $0 -d domains.txt -t tld.txt         # Serial mode, with TLD expansions"
  echo "  $0 -d domains.txt -m parallel -c 4   # Parallel mode with concurrency=4"
  echo
  exit 1
}

################################################################################
#                          Parse Command-Line Args                             #
################################################################################

DOMAINS_FILE="$DEFAULT_DOMAINS_FILE"
TLD_FILE="$DEFAULT_TLD_FILE"
OUTPUT_DIR="$DEFAULT_OUTPUT_DIR"
MODE="$DEFAULT_MODE"
CONCURRENCY="$DEFAULT_CONCURRENCY"

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
    -m|--mode)
      MODE="$2"
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

# Validate required domains file
if [[ -z "$DOMAINS_FILE" ]]; then
  echo "[!] Error: You must specify a domains file with -d or --domains."
  usage
fi

# Validate mode
if [[ "$MODE" != "serial" && "$MODE" != "parallel" ]]; then
  echo "[!] Error: --mode must be 'serial' or 'parallel'."
  usage
fi

################################################################################
#                                Banner / Intro                                #
################################################################################

cat << "EOF"

    ____                        _          
   / __ \____  ____ ___  ____ _(_)___      
  / / / / __ \/ __ `__ \/ __ `/ / __ \     
 / /_/ / /_/ / / / / / / /_/ / / / / /     
/_____/\____/_/ /_/ /_/\__,_/_/_/ /_/__    
  / ___/___  ____  / /_(_)___  ___  / /    
  \__ \/ _ \/ __ \/ __/ / __ \/ _ \/ /     
 ___/ /  __/ / / / /_/ / / / /  __/ /      
/____/\___/_/ /_/\__/_/_/ /_/\___/_/       

A Tool to Detect Typosquatting, Phishing, and Fraud

Developed by Stacy Christakos
EOF

echo
echo "[>] Execution Mode: $MODE"
[[ "$MODE" == "parallel" ]] && echo "[>] Concurrency: $CONCURRENCY"
echo

################################################################################
#                              Pre-Flight Checks                               #
################################################################################

# Check for network connectivity (simple check)
echo "[>] Checking network connectivity..."
if ! ping -c 1 8.8.8.8 &>/dev/null; then
  echo "[!] Warning: Unable to ping 8.8.8.8. Network might be down."
  echo "[!] Continuing might lead to errors. Press Ctrl+C to abort, or wait 5s to continue."
  sleep 5
else
  echo "[>] Network connectivity is okay."
fi

# Check for dnstwist installation
echo "[>] Checking if dnstwist is installed..."
if ! command -v dnstwist >/dev/null 2>&1; then
  echo "[!] Error: dnstwist not found. Please install it (e.g. sudo apt install dnstwist)."
  exit 1
fi
echo "[>] dnstwist is installed."

# Check the domains file
if [[ ! -f "$DOMAINS_FILE" ]]; then
  echo "[!] Error: Domains file '$DOMAINS_FILE' not found!"
  exit 1
fi
if [[ ! -s "$DOMAINS_FILE" ]]; then
  echo "[!] Error: Domains file '$DOMAINS_FILE' is empty!"
  exit 1
fi

# Check if TLD file exists and is non-empty
TLD_MODE=false
if [[ -n "$TLD_FILE" && -f "$TLD_FILE" && -s "$TLD_FILE" ]]; then
  TLD_MODE=true
  echo "[>] TLD file found: $TLD_FILE"
else
  if [[ -n "$TLD_FILE" ]]; then
    echo "[!] TLD file '$TLD_FILE' not found or empty. No TLD expansions will be used." else
    echo "[!] No TLD file specified. No TLD expansions will be used."
  fi
fi

echo

################################################################################
#                          Build Final Domain List                             #
################################################################################

TEMP_LIST="$(mktemp)"

mapfile -t DOMAINS < "$DOMAINS_FILE"

if $TLD_MODE; then
  mapfile -t TLDS < "$TLD_FILE"
fi

echo "[>] Building final domain list..."
for domain in "${DOMAINS[@]}"; do
  echo "$domain" >> "$TEMP_LIST"

  if $TLD_MODE; then
    # naive approach: take substring before the first dot, then append TLDs
    domain_root="${domain%%.*}"
    for tld in "${TLDS[@]}"; do
      echo "${domain_root}.${tld}" >> "$TEMP_LIST"
    done
  fi
done

LINE_COUNT="$(wc -l < "$TEMP_LIST")"
echo "[>] Total domains (including expansions): $LINE_COUNT"
echo

################################################################################
#                           Worker Function                                    #
################################################################################

run_dnstwist_for_domain() {
  local dom="$1"
  echo "[+] Enumerating: $dom"
  dnstwist -rmg "$dom" --format csv | sed 's/ *, */,/g' > "${dom}.csv"
}

################################################################################
#                           Serial vs Parallel Mode                            #
################################################################################

if [[ "$MODE" == "serial" ]]; then
  echo "[!] Starting enumeration in SERIAL mode..."
  echo
  while IFS= read -r domain; do
    run_dnstwist_for_domain "$domain"
  done < "$TEMP_LIST"

else
  # parallel mode
  echo "[!] Starting enumeration in PARALLEL mode..."
  echo
  if ! command -v xargs >/dev/null 2>&1; then
    echo "[!] xargs not found. Falling back to serial mode..."
    while IFS= read -r domain; do
      run_dnstwist_for_domain "$domain"
    done < "$TEMP_LIST"
  else
    < "$TEMP_LIST" xargs -I{} -P "$CONCURRENCY" bash -c '
      dom="$1"
      echo "[+] Enumerating: $dom"
      dnstwist -rmg "$dom" --format csv | sed "s/ *, */,/g" > "${dom}.csv"
    ' _ {}
  fi
fi

echo

################################################################################
#                            Archive CSV Results                               #
################################################################################

TIMESTAMP="$(date +%Y-%m-%d)"
ARCHIVE_DIR="${OUTPUT_DIR}/${TIMESTAMP}"

echo "[>] Archiving CSV files to: $ARCHIVE_DIR"
mkdir -p "$ARCHIVE_DIR"

mv ./*.csv "$ARCHIVE_DIR" 2>/dev/null || true

################################################################################
#                                   Cleanup                                    #
################################################################################

rm -f "$TEMP_LIST"

echo
echo "[>] Domain enumeration complete!"
echo "[>] Exiting..."
exit 0
