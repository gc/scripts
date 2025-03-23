#!/bin/bash
set -e

error() {
  echo "Error: $1"
  exit 1
}

warn() {
  echo "Warning: $1"
}

[ "$EUID" -ne 0 ] && error "Must run as root"

echo "Checking mounted filesystems..."
while read -r name fstype mountpoint; do
  dev="/dev/$name"
  [ -z "$fstype" ] && continue
  case "$fstype" in
    ext[2-4])
      dumpe2fs -h "$dev" >/dev/null 2>&1 || error "Filesystem error on $dev"
      ;;
    xfs)
      command -v xfs_info &>/dev/null || warn "xfs_info not found"
      xfs_info "$mountpoint" >/dev/null 2>&1 || error "Filesystem error on $dev"
      ;;
  esac
done < <(lsblk -o NAME,FSTYPE,MOUNTPOINT -n)

echo "Checking unmounted partitions..."
for name in $(lsblk -o NAME -n | grep -E "^[sv]d[a-z][0-9]"); do
  dev="/dev/$name"
  if ! mountpoint -q "$(lsblk -n -o MOUNTPOINT "$dev" 2>/dev/null)" 2>/dev/null; then
    fsck -n "$dev" >/dev/null 2>&1 || error "Filesystem error on $dev"
  fi
done

echo "Checking partition layout..."
if ! command -v parted &>/dev/null; then
  warn "parted not installed, skipping partition checks"
else
  for disk in $(lsblk -d -o NAME -n | grep -E "^[sv]d[a-z]"); do
    parted -s "/dev/$disk" print >/dev/null 2>&1 || error "Partition table error on /dev/$disk"
  done
fi

echo "Checking disk space..."
if df --help 2>/dev/null | grep -q -- '--total'; then
  last_line="$(df -h --total | tail -n 1)"
else
  last_line="$(df -h | tail -n 1)"
fi
used="$(echo "$last_line" | awk '{print $3}')"
avail="$(echo "$last_line" | awk '{print $4}')"

echo "Partitions (Name Size FS Mount):"
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT -n

echo "Total Used: $used, Available: $avail"
echo "SUCCESS"
