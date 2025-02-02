# Domain Sentinel
dnstwist phishing domain scanner and other tools alike are great at detect phishing and fraudulent domains but can be tedious when trying to scan more than a single domain at a time.
Domain Sentinel is a tool that automates domain enumeration with dnswist to detect phishing and fraudulent sites with a shell script utilising dnstwist.

More info regarding dnstwist can be found here: https://github.com/elceef/dnstwist

Below is a step-by-step guide on how to use the Domain Sentinel tool (the Bash script) for detecting and enumerating phishing domains. This guide covers what it does, how to prepare, how to run, and how to interpret the results.

# Domain Sentinel: A How-To Guide

## 1. Overview

Domain Sentinel is a bash script that leverages the dnstwist tool to:

- Take a list of target domains from a file.
- Optionally create expanded domain permutations based on a list of TLDs (top-level domains).
- Run dnstwist against each domain to detect potential typosquatters or phishing sites.
- Archive all results (in CSV format) into a dated folder for easy reference.
- You can choose between serial enumeration (one domain at a time) or parallel enumeration (multiple domains simultaneously). Parallel runs are faster if you have many domains and enough CPU/network capacity.

## 2. Prerequisites

Operating System: Typically, a Linux environment. The script should also work on macOS with brew-installed tools, but it’s primarily designed for Linux.

dnstwist: Install it via sudo apt install dnstwist on Debian/Ubuntu-based distros, or use your distro’s package manager.
More info on dnstwist installation can be found here: https://github.com/elceef/dnstwist

Bash: Make sure your system has a Bash shell (/bin/bash).

xargs (for parallel mode): Most Linux systems include xargs by default (part of findutils).

## 3. Getting the script

Save the script ds.sh (or any name you prefer).

Make it Executable:

```
chmod +x ds.sh
```
Place it anywhere on your system. You can run it from its current directory or put it in your $PATH (e.g., /usr/local/bin).

## 4. Preparing Input Files
 
### The Domains File

Create a text file containing each target domain on a new line.

 ```
example.com
example.net
company.org
```

You can name this file anything you want, specify it with -d <filename> when running the script.

### The TLD File (Optional)

If you want to expand each domain to additional TLDs, create a file listing TLDs you want tested. For example:

```
net
org
io
co
```

For each base domain (e.g. example.com), the script creates a new CSV named <base_domain>.csv.
Runs dnstwist on the base domain, appending its findings to <base_domain>.csv.
If TLD mode is on, it enumerates expansions like example.org, example.io, etc., appending each expansion’s results to the same <base_domain>.csv.

If you omit this file or leave it empty, no extra expansions are generated.

## 5. Script Usage

The script supports command-line options to specify files, mode, and concurrency. Run:

```
./ds.sh --help
```

to see usage details, which look like this:
```
Usage: ./ds.sh [OPTIONS]

OPTIONS:
  -d, --domains [file]          Path to domains file (REQUIRED)
  
  -t, --tld [file]              Path to optional TLD file (example: tld.txt)
  
  -o, --output [dir]            Directory to archive results (default: archived_results)
  
  -m, --mode [serial|parallel]  Execution mode (default: serial)
  
  -c, --concurrency [number]    Number of parallel jobs (default: 2)
  
  -h, --help                    Show this help message and exit
```
### Required Options?

At a minimum, you need a domains file with at least one domain in it. By default, the script will look for domains.txt. If your file has a different name, pass -d <filename>.
TLD file is optional; if present and non-empty, it will create domain expansions.

### Mode: Serial vs. Parallel

Serial (-m serial): Processes each domain one at a time. Slower, but simpler.
Parallel (-m parallel): Runs multiple dnstwist processes at once, controlled by --concurrency.

### Concurrency

Only matters if you use parallel mode. Determines how many domains are processed simultaneously. A value of 2 or 4 is common.

## 6. Example Commands

### Basic: Just a Domains File (Serial)

```
./ds.sh -d domains.txt
```

Reads domains.txt, enumerates them one by one.
No TLD expansions occur since -t wasn’t specified.

### Parallel Mode

```
./ds.sh -d domains.txt -m parallel -c 4
```

Still no TLD expansions if no -t file.
Runs 4 processes in parallel.

### Domains + TLD Expansions

```
./ds.sh -d domains.txt -t custom_tlds.txt
```

Serial (default) mode with expansions for each domain.
If custom_tlds.txt is present and non-empty, the script enumerates each domain plus each domain + TLD combination.

### Specify a Different Output Directory

```
./ds.sh -d domains.txt -o /home/user/dns_results
```

Saves all CSV files under /home/user/dns_results/YYYY-MM-DD/.

## 7. Output and Interpretation

### Generated CSV Files

For each domain scanned by dnstwist, a CSV file is produced. For example, if you have example.com, you’ll see:
```
example.com.csv
```
Each CSV has columns typically including:

Fuzzer: Name of the mutation type used by dnstwist (e.g., omission, repetition).
Domain: The variant domain name tested.
DNS A: IP addresses associated with that domain.
DNS AAAA: IPv6 addresses.
MX, NS, etc.: DNS records.
Banner: Additional info if dnstwist does HTTP or SMTP checks.

### Archive Directory

All CSVs are moved into a dated folder, for example:
```
archived_results/2025-01-31/
└── example.com.csv
└── example.net.csv
└── mycustomdomain.com.csv
```
This ensures you can easily keep and revisit historical scans. If you run the script multiple times in one day, each run’s CSV files will go into the same daily folder (unless you rename the folder or run the script on different days).

If TLD mode is on, it enumerates expansions like example.org, example.io, etc., appending each expansion’s results to the same <base_domain>.csv.

## 8. Tips & Best Practices

### Check DNS and Network

If your system has DNS or connectivity issues, dnstwist may fail to resolve domains accurately.
Make sure you’re online and have the necessary DNS access.

### Use Parallel Wisely

If you have an extensive domain list, parallelization is helpful.
However, if your network or DNS resolvers can’t handle many simultaneous queries, you could experience slower or unreliable results.

### Clean TLD List

Avoid “unrelated” TLDs or duplicates in tld.txt. The script systematically combines them with your root domain, which can clutter results.

### Interpretation

A dnstwist CSV output showing an existing domain that’s suspiciously similar to yours could be a sign of phishing or typosquatting. Investigate further!

### Combine with Other Tools

You might feed this data into security tools or SIEM solutions to block suspicious domains or gather threat intelligence.

## 9. Troubleshooting

*dnstwist not found*
    
Make sure you’ve installed it (sudo apt install dnstwist).

*Domains file not found or empty*

Double-check your -d parameter and that the file actually contains domain lines.

*CSV not generated*

If dnstwist fails or network issues arise, you might get empty CSV files or errors in your terminal.

## 10. Conclusion

Domain Sentinel is a straightforward yet powerful script for discovering potential domain impersonations and typosquatters. By leveraging dnstwist, it scans each domain you provide, optionally expanding them with a TLD list. Depending on your needs, you can run it serially (safer for small domain sets) or in parallel (faster for large lists).

Once it’s finished, check the archived CSV files to see which permutations resolve, which IPs they map to, and whether they might represent a threat to your brand or users.

Happy scanning—and stay vigilant!
