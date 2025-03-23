#!/bin/bash
set -e

curl -sSL https://raw.githubusercontent.com/gc/scripts/master/checks.sh | bash
curl -sSL https://raw.githubusercontent.com/gc/scripts/master/check_disk.sh | bash
curl -sSL https://raw.githubusercontent.com/gc/scripts/master/check_network.sh | bash
