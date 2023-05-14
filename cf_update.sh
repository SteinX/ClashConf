#!/bin/bash
set -euo pipefail

# The path to the dnsmasq configuration file
readonly DNSMASQ_CONFIG_PATH="/etc/dnsmasq.conf"
# The path to the file with the test results
readonly CF_TEST_RESULTS="/usr/share/cloudflarespeedtestresult.csv"
# The path to the file with the list of IPs to test
readonly CF_IPV4_LIST="/usr/share/CloudflareSpeedTest/ipv4.txt"

# First of all, update the list of IPs to test
curl -o $CF_IPV4_LIST https://raw.githubusercontent.com/SteinX/ClashConf/main/cf_ipv4.txt

/usr/bin/cdnspeedtest \
    -httping \
    -o $CF_TEST_RESULTS \
    -f $CF_IPV4_LIST

# The hosts for which the IP resolution should be updated
# You might need to adjust this line to fit your exact needs
readonly TARGET_HOSTS=(
    "hdarea.co"
    "azusa.wiki"
    "hhanclub.top"
    "haidan.video"
    "hdtime.org"
    "m-team.cc"
    "audiences.me"
)

# Extract the IP address of the best result (first line, first column)
BEST_IP=$(awk -F ',' 'NR==2 {print $1}' "$CF_TEST_RESULTS")
readonly BEST_IP

# Update the dnsmasq configuration file
for HOST in "${TARGET_HOSTS[@]}"; do
    # First, remove any existing resolution for this host
    sed -i.bak "/address=\/$HOST\//d" "$DNSMASQ_CONFIG_PATH"

    # Then, add the new resolution with the best IP
    echo "address=/$HOST/$BEST_IP" | tee -a "$DNSMASQ_CONFIG_PATH"
done

/etc/init.d/dnsmasq restart
