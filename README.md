# CyberSquatter
A simple shell script used in conjunction with dnstwist to detect typo squatted domains.
More info regarding dnstwist can be found here: https://github.com/elceef/dnstwist

How the Script Works:

Command-Line Arguments:

-d, --domains - Provide a custom path to your domain list. Defaults to domains.txt.

-t, --tld - Provide a path to an optional TLD file. Defaults to tld.txt.

-o, --output - Provide a custom directory for archived results. Defaults to archived_results.

-c, --concurrency - Number of parallel jobs. Defaults to 4.

-h, --help - Displays usage info.

Pre-Flight Checks:

Verifies that dnstwist is installed.
Checks basic network connectivity by pinging 8.8.8.8 (Google DNS).
Ensures the specified domains file is present and non-empty.
If the TLD file is present and non-empty, the script goes into “TLD mode,” generating additional permutations.

Handling TLD File:

If tld.txt is found, for each domain in domains.txt, the script adds:
The original domain itself (e.g., example.com)
Variations that combine the first portion of the domain with each TLD (e.g., example.net, example.io, etc.).
All permutations are written to a temporary file.

Parallelization:

Checks if parallel is installed. If yes, uses GNU parallel to run multiple dnstwist processes simultaneously.
If parallel is missing, falls back to xargs -P <concurrency> for parallel processing.
The number of simultaneous jobs is controlled by the --concurrency <number> argument.

Archiving:

By default, all generated CSV files go to archived_results/<YYYY-MM-DD> (or the directory you specify via -o).
If that directory doesn’t exist, the script will create it.
Then, it moves all CSV files into that directory.

Clean Up:

Removes the temporary domain list.S
Prints a final completion message.

