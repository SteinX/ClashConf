#!/bin/bash
set -eu pipefail

# The path to the dnsmasq configuration file
readonly DNSMASQ_CONFIG_PATH="/etc/dnsmasq.conf"
# The path to the file with the test results
readonly CF_TEST_RESULTS="/usr/share/cloudflarespeedtestresult.txt"

/usr/bin/cdnspeedtest \
    -url https://cf.xiu2.xyz/url \
    -o $CF_TEST_RESULTS \
    -f /usr/share/CloudflareSpeedTest/ip.txt \
    -dn 1

# The hosts for which the IP resolution should be updated
# You might need to adjust this line to fit your exact needs
TARGET_HOSTS=(
    "hdarea.co"
    "azusa.wiki"
    "hhanclub.top"
    "haidan.video"
    "hdtime.org"
    "m-team.cc"
    "audiences.me"
)

# Extract the IP address of the best result (first line, first column)
readonly BEST_IP=$(awk -F ',' 'NR==2 {print $1}' "$CF_TEST_RESULTS")

# Update the dnsmasq configuration file
for HOST in "${TARGET_HOSTS[@]}"; do
    # First, remove any existing resolution for this host
    sed -i.bak "/address=\/$HOST\//d" "$DNSMASQ_CONFIG_PATH"

    # Then, add the new resolution with the best IP
    echo "address=/$HOST/$BEST_IP" | tee -a "$DNSMASQ_CONFIG_PATH"
done

/etc/init.d/dnsmasq restart
