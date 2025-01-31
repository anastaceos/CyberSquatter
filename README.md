# Domain Sentinel
A shell script used in conjunction with dnstwist to detect potential typosquatters or phishing sites.
More info regarding dnstwist can be found here: https://github.com/elceef/dnstwist

Below is a step-by-step guide on how to use the CyberSquatter tool (the Bash script) for detecting and enumerating typosquatted or phishing domains. This guide covers what it does, how to prepare, how to run, and how to interpret the results.

Domain Sentinel: A How-To Guide

1. Overview
Domain Sentinel is a Bash script that leverages the dnstwist tool to:

Take a list of target domains from a file.
Optionally create expanded domain permutations based on a list of TLDs (top-level domains).
Run dnstwist against each domain to detect potential typosquatters or phishing sites.
Archive all results (in CSV format) into a dated folder for easy reference.
You can choose between serial enumeration (one domain at a time) or parallel enumeration (multiple domains simultaneously). Parallel runs are faster if you have many domains and enough CPU/network capacity.

2. Prerequisites

Operating System: Typically, a Linux environment. The script should also work on macOS with brew-installed tools, but it’s primarily designed for Linux.
dnstwist:
Install it via sudo apt install dnstwist on Debian/Ubuntu-based distros, or use your distro’s package manager.
If using macOS: brew install dnstwist.
Bash: Make sure your system has a Bash shell (/bin/bash).
xargs (for parallel mode): Most Linux systems include xargs by default (part of findutils).

3. Getting the script

Save the Script as CyberSquatter.sh (or any name you prefer).
Make it Executable:

chmod +x CyberSquatter.sh

Place it anywhere on your system. You can run it from its current directory or put it in your $PATH (e.g., /usr/local/bin).

4. Preparing Input Files

4.1 The Domains File
Create a text file containing each target domain on a new line.
text
Copy
Edit
example.com
example.net
company.org
...
By default, the script looks for domains.txt in the current directory.
You can name this file anything you want—just specify it with -d <filename> when running the script.

4.2 The TLD File (Optional)
If you want to expand each domain to additional TLDs, create a file listing TLDs you want tested. For example:

net
org
io
co
...
By default, the script looks for tld.txt.
If you omit this file, or leave it empty, no extra expansions are generated.

5. Script Usage
The script supports command-line options to specify files, mode, and concurrency. Run:

./CyberSquatter.sh --help
to see usage details, which look like this:

Usage: ./CyberSquatter.sh [OPTIONS]

OPTIONS:
  -d, --domains <file>         Path to domains file (REQUIRED)
  -t, --tld <file>             Path to TLD file (default: tld.txt)
  -o, --output <dir>           Directory to archive results (default: archived_results)
  -m, --mode <serial|parallel> Execution mode (default: serial)
  -c, --concurrency <number>   Number of parallel jobs (default: 2)
  -h, --help                   Show this help message and exit

5.1 Required Options?
At a minimum, you need a domains file with at least one domain in it. By default, the script will look for domains.txt. If your file has a different name, pass -d <filename>.
TLD file is optional; if present and non-empty, it will create domain expansions.

5.2 Mode: Serial vs. Parallel
Serial (-m serial): Processes each domain one at a time. Slower, but simpler.
Parallel (-m parallel): Runs multiple dnstwist processes at once, controlled by --concurrency.

5.3 Concurrency
Only matters if you use parallel mode. Determines how many domains are processed simultaneously. A value of 2 or 4 is common.

6. Example Commands
Basic Run (Serial, Defaults)

./CyberSquatter.sh
Looks for domains.txt and tld.txt in the current folder.
Runs each domain serially.
Archives CSV outputs in archived_results/YYYY-MM-DD/.
Parallel Execution

./CyberSquatter.sh --mode parallel --concurrency 4
Still uses domains.txt and tld.txt.
Spawns 4 dnstwist jobs at a time.
Custom Domain & TLD Files, Parallel

./CyberSquatter.sh \
    -d my_domains.txt \
    -t custom_tlds.txt \
    -m parallel \
    -c 6

Reads domains from my_domains.txt.
Expands them using TLDs from custom_tlds.txt.
Runs with 6 parallel jobs.
Archives to archived_results/.

Specify a Different Output Directory

./CyberSquatter.sh -o /home/user/dns_results

Saves all CSV files under /home/user/dns_results/YYYY-MM-DD/.
Help/Usage

./CyberSquatter.sh --help

7. Output and Interpretation

7.1 Generated CSV Files
For each domain scanned by dnstwist, a CSV file is produced. For example, if you have example.com, you’ll see:

example.com.csv

Each CSV has columns typically including:

Fuzzer: Name of the mutation type used by dnstwist (e.g., omission, repetition).
Domain: The variant domain name tested.
DNS A: IP addresses associated with that domain.
DNS AAAA: IPv6 addresses.
MX, NS, etc.: DNS records.
Banner: Additional info if dnstwist does HTTP or SMTP checks.

7.2 Archive Directory
All CSVs are moved into a dated folder, for example:

archived_results/2025-01-31/
└── example.com.csv
└── example.net.csv
└── mycustomdomain.com.csv
   ...
This ensures you can easily keep and revisit historical scans. If you run the script multiple times in one day, each run’s CSV files will go into the same daily folder (unless you rename the folder or run the script on different days).

8. Tips & Best Practices
Check DNS and Network

If your system has DNS or connectivity issues, dnstwist may fail to resolve domains accurately.
Make sure you’re online and have the necessary DNS access.
Use Parallel Wisely

If you have a very large domain list, parallelization is helpful.
However, if your network or DNS resolvers can’t handle many simultaneous queries, you could experience slower or unreliable results.
Clean TLD List

Avoid “unrelated” TLDs or duplicates in tld.txt. The script will systematically combine them with your root domain, which can clutter results.
Interpretation

A dnstwist CSV output showing an existing domain that’s suspiciously similar to yours could be a sign of phishing or typosquatting. Investigate further!
Combine with Other Tools

You might feed this data into security tools or SIEM solutions to block suspicious domains or gather threat intelligence.

9. Troubleshooting
dnstwist not found: Make sure you’ve installed it (sudo apt install dnstwist).
“Domains file not found or empty”: Double-check your -d parameter and that the file actually contains domain lines.
CSV not generated: If dnstwist fails or network issues arise, you might get empty CSV files or errors in your terminal.

10. Conclusion
CyberSquatter is a straightforward yet powerful script for discovering potential domain impersonations and typosquatters. By leveraging dnstwist, it scans each domain you provide, optionally expanding them with a TLD list. Depending on your needs, you can run it serially (safer for small domain sets) or in parallel (faster for large lists).

Once it’s finished, check the archived CSV files to see which permutations resolve, which IPs they map to, and whether they might represent a threat to your brand or users.

Happy scanning—and stay vigilant!