#!/bin/bash

set -e

EXPECTED_TIMEZONE="UTC"
EXPECTED_ULIMIT=65535

CURRENT_TZ=$(timedatectl show -p Timezone --value)
[ "$CURRENT_TZ" = "$EXPECTED_TIMEZONE" ] || { echo "FAIL: Timezone is $CURRENT_TZ, expected $EXPECTED_TIMEZONE"; exit 1; }
echo "Timezone: $CURRENT_TZ ✓"

CURRENT_SSH_PORT=$(sshd -T | grep '^port ' | awk '{print $2}')
[ "$CURRENT_SSH_PORT" != "22" ] || { echo "FAIL: SSH port is 22, expected not 22"; exit 1; }
echo "SSH Port: $CURRENT_SSH_PORT ✓"

sshd -T | grep -q "^permitrootlogin no" || { echo "FAIL: PermitRootLogin not set to no"; exit 1; }
sshd -T | grep -q "^passwordauthentication no" || { echo "FAIL: PasswordAuthentication not set to no"; exit 1; }
echo "RootLogin/PasswordAuth OFF ✓"

ufw status | grep -q "Status: active" || { echo "FAIL: UFW is not active"; exit 1; }
echo "UFW active ✓"

if [ "$(id -u)" -eq 0 ] && [ -n "$SUDO_USER" ]; then
  CURRENT_LIMIT=$(sudo -u "$SUDO_USER" bash -c 'ulimit -n')
  TARGET_USER="$SUDO_USER"
else
  CURRENT_LIMIT=$(ulimit -n)
  TARGET_USER="$USER"
fi

[ "$CURRENT_LIMIT" -ge "$EXPECTED_ULIMIT" ] || {
  echo "FAIL: ulimit -n for $TARGET_USER is $CURRENT_LIMIT, expected >= $EXPECTED_ULIMIT"
  exit 1
}
echo "ulimit $CURRENT_LIMIT ✓"

HOSTNAME=$(hostname)
grep -q "$HOSTNAME" /etc/hosts || { echo "FAIL: Hostname $HOSTNAME not found in /etc/hosts"; exit 1; }
echo "Hostname: ${HOSTNAME} ✓"