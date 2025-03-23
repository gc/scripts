#!/bin/bash

set -e

log_echo() {
    echo "$1"
}

ip -4 addr show || log_echo "Warning: Failed to list IPv4 interfaces"
if [ -z "$(ip -4 addr show | grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+')" ]; then
    log_echo "Error: No active IPv4 interfaces found"
fi

log_echo "Checking IPv4 connectivity..."
for target in "8.8.8.8" "1.1.1.1" "google.com"; do
    log_echo "Pinging $target..."
    if ping -c 4 -W 2 "$target"; then
        log_echo "Success: $target is reachable"
    else
        log_echo "Warning: Failed to reach $target"
    fi
done

log_echo "Checking DNS resolution..."
for domain in "google.com" "cloudflare.com"; do
    log_echo "Resolving $domain..."
    if dig +short "$domain"; then
        log_echo "Success: $domain resolved successfully"
    else
        log_echo "Warning: DNS resolution failed for $domain"
    fi
done

my_hostname=$(hostname)
if [ -z "$my_hostname" ]; then
    log_echo "Error: Hostname is not set"
else
    log_echo "Current hostname: $my_hostname"
    if dig +short "$my_hostname"; then
        log_echo "Success: Hostname $my_hostname resolves"
    else
        log_echo "Warning: Hostname $my_hostname does not resolve"
    fi
    if ping -c 4 -W 2 "$my_hostname"; then
        log_echo "Success: Hostname $my_hostname is pingable"
    else
        log_echo "Warning: Hostname $my_hostname not reachable"
    fi
fi

gateway=$(ip route | grep default | awk '{print $3}')
if [ -z "$gateway" ]; then
    log_echo "Error: No default gateway found"
else
    log_echo "Default gateway: $gateway"
    if ping -c 4 -W 2 "$gateway"; then
        log_echo "Success: Gateway $gateway is reachable"
    else
        log_echo "Warning: Gateway $gateway not reachable"
    fi
fi

if curl -s -I "https://www.google.com" > /dev/null; then
    log_echo "Success: HTTP access to google.com works"
else
    log_echo "Warning: HTTP access to google.com failed"
fi

if [ -f /etc/resolv.conf ]; then
    log_echo "Contents of /etc/resolv.conf:"
    cat /etc/resolv.conf
    for ns in $(grep '^nameserver' /etc/resolv.conf | awk '{print $2}'); do
        log_echo "Testing nameserver $ns..."
        if ping -c 4 -W 2 "$ns"; then
            log_echo "Success: Nameserver $ns is reachable"
        else
            log_echo "Warning: Nameserver $ns not reachable"
        fi
    done
else
    log_echo "Warning: /etc/resolv.conf not found"
fi

if systemctl is-active network-online.target > /dev/null; then
    log_echo "Success: Network online target is active"
else
    log_echo "Warning: Network online target is not active"
fi

log_echo "Network Check Summary:"
log_echo "Interfaces found: $(ip -4 addr show | grep -c 'inet ' || echo 0)"


log_echo "Networking ✓"