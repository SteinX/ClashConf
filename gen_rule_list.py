#!/usr/bin/env python3
from optparse import OptionParser
import requests

DEFAULT_URL = "https://raw.githubusercontent.com/v2fly/domain-list-community/refs/heads/master/data/meta"

def fetch_and_process_domains(url):
    print(f"Fetching domains from: {url}")
    response = requests.get(url)
    print(f"Response status code: {response.status_code}")
    lines = response.text.splitlines()
    domains = set()
    
    print(f"Processing {len(lines)} lines from {url}")
    for line in lines:
        line = line.strip()
        if line and not line.startswith('#'):
            if line.startswith('include:'):
                include_name = line.split(':')[1]
                include_url = f'https://raw.githubusercontent.com/v2fly/domain-list-community/refs/heads/master/data/{include_name}'
                domains.update(fetch_and_process_domains(include_url))
            else:
                if '@' in line:
                    line = line.split('@')[0].strip()
                
                if line.startswith('full:'):
                    domain = line[5:]
                    line = f'DOMAIN,{domain}'
                elif not line.startswith('DOMAIN'):
                    line = f'DOMAIN-SUFFIX,{line}'
                domains.add(line)
    
    print(f"Found {len(domains)} unique domains from {url}")
    return domains

print("Domain list generator starting...")

parser = OptionParser()
parser.add_option("-i", "--input", dest="input_file",
                  help="File to read from and write to", metavar="FILE")
parser.add_option("-u", "--url", dest="url",
                  help="URL to fetch domain list from (default: %s)" % DEFAULT_URL,
                  default=DEFAULT_URL)
(options, args) = parser.parse_args()

if not options.input_file:
    parser.error("Input file is required")

online_domains = set()
if options.url:
    print(f"Fetching online domain list from: {options.url}")
    online_domains = fetch_and_process_domains(options.url)
    print(f"Retrieved {len(online_domains)} domains from online source")

print(f"Reading from file: {options.input_file}")
processed_lines = set()

try:
    with open(options.input_file, 'r') as file:
        lines = file.readlines()
    print(f"Read {len(lines)} lines from existing file")
    
    for line in lines:
        line = line.strip()
        if line:
            if not line.startswith('DOMAIN-SUFFIX,'):
                line = f'DOMAIN-SUFFIX,{line}'
            processed_lines.add(line)

except FileNotFoundError:
    print(f"File {options.input_file} does not exist, will create a new one")
    lines = []

# 合并在线域名和本地域名
processed_lines.update(online_domains)
print(f"Total {len(processed_lines)} unique domain entries after merging")

sorted_lines = sorted(processed_lines)

print(f"Writing {len(sorted_lines)} lines back to {options.input_file}")
with open(options.input_file, 'w') as file:
    file.write('\n'.join(sorted_lines))
print("Done!")