#!/usr/bin/env bash
#
# Domain Sentinel: A tool that automates domain enumeration with dnstwist.
# Used to detect phishing and fraudulent domains.
# By Anastaceos
#
# This script:
#   - Requires a domains file (-d).
#   - Optionally takes a TLD file (-t). If provided, expansions are generated.
#   - Can run in either serial or parallel mode.
#   - Archives CSV outputs to a dated folder under --output.
#   - Appends expansions to the same CSV as the base domain (e.g., example.com.csv).
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
  echo "     ____                        _            "  
  echo "    / __ \____  ____ ___  ____ _(_)___        "
  echo "   / / / / __ \/ __ \__ \/ __ \/ / __ \       "
  echo "  / /_/ / /_/ / / / / / / /_/ / / / / /       "
  echo " /_____/\____/_/ /_/ /_/\__,_/_/_/ /_/  __    "
  echo "     / ___/___  ____  / /_(_)___  ___  / /    "
  echo "     \__ \/ _ \/ __ \/ __/ / __ \/ _ \/ /     "
  echo "    ___/ /  __/ / / / /_/ / / / /  __/ /      "
  echo "   /____/\___/_/ /_/\__/_/_/ /_/\___/_/       "                                          
  echo 
  echo "Commandline utility that automates domain enumeration with dnstwist."
  echo "Used to detect phishing and fraudulent domains at scale and export to csv."
  echo 
  echo "More information on dnstwist can be found at https://github.com/elceef/dnstwist"
  echo
  echo "Usage: $0 [OPTIONS]"
  echo
  echo "OPTIONS:"
  echo "  -d, --domains <file>         Path to the domains file (REQUIRED)"
  echo "  -t, --tld <file>             Path to an OPTIONAL TLD file (if provided, expansions are generated)"
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

# Initialize variables with defaults
DOMAINS_FILE="$DEFAULT_DOMAINS_FILE"
TLD_FILE="$DEFAULT_TLD_FILE"
OUTPUT_DIR="$DEFAULT_OUTPUT_DIR"
MODE="$DEFAULT_MODE"
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
   / / / / __ \/ __ \__ \/ __ \/ / __ \       
  / /_/ / /_/ / / / / / / /_/ / / / / /       
 /_____/\____/_/ /_/ /_/\__,_/_/_/ /_/  __    
     / ___/___  ____  / /_(_)___  ___  / /    
     \__ \/ _ \/ __ \/ __/ / __ \/ _ \/ /     
    ___/ /  __/ / / / /_/ / / / /  __/ /      
   /____/\___/_/ /_/\__/_/_/ /_/\___/_/       

Commandline utility that automates domain enumeration with dnstwist.
Used to detect phishing and fraudulent domains at scale and export to csv.

More information on dnstwist can be found at https://github.com/elceef/dnstwist

EOF

echo
echo "[>] Execution Mode: $MODE"
# Print concurrency only if in parallel mode
[[ "$MODE" == "parallel" ]] && echo "[>] Concurrency: $CONCURRENCY"
echo

################################################################################
#                              Pre-Flight Checks                               #
################################################################################

# (1) Network check
echo "[>] Checking network connectivity..."
if ! ping -c 4 8.8.8.8 &>/dev/null; then
  echo "[!] Warning: Unable to ping 8.8.8.8. Network might be down."
  echo "[!] Continuing might lead to errors. Press Ctrl+C to abort, or wait 5s to continue."
  sleep 5
else
  echo "[>] Network connectivity is okay."
fi

# (2) dnstwist check
echo "[>] Checking if dnstwist is installed..."
if ! command -v dnstwist >/dev/null 2>&1; then
  echo "[!] Error: dnstwist not found. Please install it (e.g., 'sudo apt install dnstwist')."
  exit 1
fi
echo "[>] dnstwist is installed."

# (3) Validate domains file
if [[ ! -f "$DOMAINS_FILE" ]]; then
  echo "[!] Error: Domains file '$DOMAINS_FILE' not found!"
  exit 1
fi
if [[ ! -s "$DOMAINS_FILE" ]]; then
  echo "[!] Error: Domains file '$DOMAINS_FILE' is empty!"
  exit 1
fi

# (4) Optional TLD file
TLD_MODE=false
if [[ -n "$TLD_FILE" && -f "$TLD_FILE" && -s "$TLD_FILE" ]]; then
  TLD_MODE=true
  echo "[>] TLD file found: $TLD_FILE"
else
  if [[ -n "$TLD_FILE" ]]; then
    echo "[!] TLD file '$TLD_FILE' not found or empty. No TLD expansions will be used."
  else
    echo "[!] No TLD file specified. No TLD expansions will be used."
  fi
fi

echo

################################################################################
#               Enumerate a Single Base Domain (Including TLDs)                #
################################################################################

# This function:
# 1. Creates or clears base_domain.csv
# 2. Runs dnstwist on the original domain, appends to base_domain.csv
# 3. If TLD_MODE is on, runs expansions (example.org, .net, etc.) also appended to base_domain.csv

enumerate_domain() {
  local base_domain="$1"

  # We'll store all results in base_domain.csv
  # Clear (or create) it at the start so we don't mix results from previous runs
  : > "${base_domain}.csv"

  # 1) Enumerate the base domain
  echo "[+] Enumerating base domain: ${base_domain}"
  dnstwist -r "${base_domain}" --format csv | sed 's/ *, */,/g' >> "${base_domain}.csv"

  # 2) If TLD_MODE is on, enumerate expansions
  if $TLD_MODE; then
    # We'll read TLDs from the array TLDS
    for tld in "${TLDS[@]}"; do
      # naive approach: take substring before the first dot
      local domain_root="${base_domain%%.*}"
      local expansion="${domain_root}.${tld}"

      # We skip enumerating if it's the same as the base domain
      if [[ "$expansion" != "$base_domain" ]]; then
        echo "[+] Enumerating expansion: ${expansion}"
        dnstwist -r "${expansion}" --format csv | sed 's/ *, */,/g' >> "${base_domain}.csv"
      fi
    done
  fi
}

################################################################################
#                          Collect Base Domains & TLDs                         #
################################################################################

# Read the base domains
mapfile -t BASE_DOMAINS < "$DOMAINS_FILE"

# If TLD_MODE is on, read TLDs into array
if $TLD_MODE; then
  mapfile -t TLDS < "$TLD_FILE"
fi

# Let's report how many domains we have
echo "[>] Found ${#BASE_DOMAINS[@]} base domains in: $DOMAINS_FILE"
if $TLD_MODE; then
  echo "[>] Found ${#TLDS[@]} TLDs in: $TLD_FILE"
fi
echo

# Calculate and print how many total domain combinations will be produced:
# Each base domain will be enumerated once, plus each TLD expansion.
if $TLD_MODE; then
  # For each base domain: 1 base + N expansions
  # So total = #base_domains * (1 + #tlds)
  total_combos=$(( ${#BASE_DOMAINS[@]} * (1 + ${#TLDS[@]}) ))
else
  # No TLD expansions, total combos = #base_domains
  total_combos=${#BASE_DOMAINS[@]}
fi

echo "[>] This run will produce a total of $total_combos domain combination(s)."
echo

################################################################################
#                           Serial vs Parallel Mode                            #
################################################################################

if [[ "$MODE" == "serial" ]]; then
  echo "[!] Starting enumeration in SERIAL mode..."
  echo
  # Just iterate through each base domain
  for dom in "${BASE_DOMAINS[@]}"; do
    enumerate_domain "$dom"
  done

else
  # PARALLEL MODE
  echo "[!] Starting enumeration in PARALLEL mode..."
  echo

  # We'll do a small check if xargs is installed
  if ! command -v xargs >/dev/null 2>&1; then
    echo "[!] xargs not found. Falling back to serial mode..."
    for dom in "${BASE_DOMAINS[@]}"; do
      enumerate_domain "$dom"
    done
  else
    # Use xargs. We'll pass the base domains via stdin, and each call to enumerate_domain runs them in parallel.
    # We first create a temp file with the base domains
    TEMP_DOM_FILE="$(mktemp)"
    for base_dom in "${BASE_DOMAINS[@]}"; do
      echo "$base_dom" >> "$TEMP_DOM_FILE"
    done

    # We'll define the function inline. We'll need to re-initialize TLDs and TLD_MODE inside the parallel call if needed.
    # So let's pass them as environment variables for convenience.

    export TLD_MODE
    export TLD_FILE
    export -f enumerate_domain
    export -f dnstwist 2>/dev/null || true   # This might fail, but it's not critical
    export -f sed 2>/dev/null || true

    # We'll also need to get the TLDs array in each sub-shell. For that, let's write them to a temporary file and source them. 
    # Or simpler approach: We'll rebuild them if TLD_MODE is on in the sub-shell. 
    # For quickness, let's do a function wrapper:

    parallel_wrapper() {
      local dom="$1"
      # Rebuild TLD array if needed
      if $TLD_MODE; then
        mapfile -t TLDS < "$TLD_FILE"
      fi
      # Now call enumerate_domain
      enumerate_domain "$dom"
    }

    export -f parallel_wrapper

    # Now we can run xargs with concurrency
    < "$TEMP_DOM_FILE" xargs -I{} -P "$CONCURRENCY" bash -c 'parallel_wrapper "$@"' _ {}

    # Clean up
    rm -f "$TEMP_DOM_FILE"
  fi
fi

echo

################################################################################
#                            Archive CSV Results                               #
################################################################################

# Create a dated subfolder in OUTPUT_DIR
TIMESTAMP="$(date +%Y-%m-%d)"
ARCHIVE_DIR="${OUTPUT_DIR}/${TIMESTAMP}"

echo "[>] Archiving CSV files to: $ARCHIVE_DIR"
mkdir -p "$ARCHIVE_DIR"

# Move all CSV files to the archive directory
mv ./*.csv "$ARCHIVE_DIR" 2>/dev/null || true

################################################################################
#                                  Done                                        #
################################################################################

echo
echo "[>] Domain enumeration complete!"
echo "[>] Exiting..."
exit 0
