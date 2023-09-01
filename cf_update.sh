#!/bin/bash
set -euo pipefail

# The path to the smartdns configuration file
readonly SMARTDNS_CONFIG_PATH="/etc/smartdns/address.conf"
# The path to the file with the test results
readonly CF_TEST_RESULTS="/usr/share/cloudflarespeedtestresult.csv"
# The path to the file with the list of IPs to test
readonly CF_IPV4_LIST="/usr/share/CloudflareSpeedTest/ipv4.txt"

# First of all, update the list of IPs to test
curl -o $CF_IPV4_LIST https://raw.githubusercontent.com/SteinX/ClashConf/main/cf_ipv4.txt

/usr/bin/cdnspeedtest \
    -o $CF_TEST_RESULTS \
    -f $CF_IPV4_LIST

# The hosts for which the IP resolution should be updated
# You might need to adjust this line to fit your exact needs
readonly TARGET_HOSTS=()

# Extract the IP address of the best result (take the second one, as the first one tend to be
# problematic in my experience)
BEST_IP=$(awk -F ',' 'NR>1{ip[NR-1]=$1} END{if(ip[2]) print ip[2]; else if(ip[1]) print ip[1]}' "$CF_TEST_RESULTS")
readonly BEST_IP

if [[ -z $BEST_IP ]]; then
    exit 0
fi

# Update the smartdns configuration file
for HOST in "${TARGET_HOSTS[@]}"; do
    # Process the file with awk to replace or retain lines.
    # If the host is not found, print a flag at the end.
    awk -v host="$HOST" -v ip="$BEST_IP" '
    BEGIN { found=0 }
    {
        if ($0 ~ "address /" host "/") {
            print "address /" host "/" ip;
            found=1;
        } else {
            print $0;
        }
    }
    END {
        if (found == 0) {
            print "NEW_HOST_ENTRY";
        }
    }' "$SMARTDNS_CONFIG_PATH" > "${SMARTDNS_CONFIG_PATH}.tmp"

    # Check if the flag is present indicating a new host entry is needed.
    if grep -q "NEW_HOST_ENTRY" "${SMARTDNS_CONFIG_PATH}.tmp"; then
        sed "$ d" "${SMARTDNS_CONFIG_PATH}.tmp" -i  # Delete the flag line
        echo "address /$HOST/$BEST_IP" >> "${SMARTDNS_CONFIG_PATH}.tmp"  # Append new host entry
    fi

    mv "${SMARTDNS_CONFIG_PATH}.tmp" "$SMARTDNS_CONFIG_PATH"
done

/etc/init.d/smartdns restart