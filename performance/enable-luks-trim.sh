#!/bin/bash
# Enable TRIM/discard support for LUKS encrypted volumes
# This script adds :allow-discards to the cryptdevice kernel parameter

set -e

echo "=== LUKS TRIM Enablement Script ==="
echo ""
echo "This will enable TRIM/discard support for your encrypted volumes."
echo ""
echo "⚠️  SECURITY NOTE:"
echo "Enabling discard on encrypted volumes may leak metadata about which"
echo "blocks are used vs free. For most users this is a minor concern."
echo ""
echo "Benefits:"
echo "  - SSD longevity (wear leveling)"
echo "  - Better performance over time"
echo "  - fstrim commands will work"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Backup boot loader entry
BOOT_ENTRY="/boot/loader/entries/$(ls /boot/loader/entries/*.conf | head -1 | xargs basename)"
echo ""
echo "Backing up boot entry: $BOOT_ENTRY"
sudo cp "$BOOT_ENTRY" "${BOOT_ENTRY}.backup"

# Add :allow-discards to cryptdevice parameter
echo "Modifying boot entry to add :allow-discards..."
sudo sed -i 's/cryptdevice=UUID=43ab711b-4882-44e2-835d-a8f3704c7394:cryptlvm/cryptdevice=UUID=43ab711b-4882-44e2-835d-a8f3704c7394:cryptlvm:allow-discards/' "$BOOT_ENTRY"

# Enable discard in LVM
echo "Enabling discard in LVM configuration..."
if ! grep -q "issue_discards = 1" /etc/lvm/lvm.conf; then
    sudo sed -i 's/# issue_discards = 0/issue_discards = 1/' /etc/lvm/lvm.conf
fi

echo ""
echo "✅ Configuration updated!"
echo ""
echo "Changes made:"
echo "  1. Added :allow-discards to cryptdevice parameter"
echo "  2. Enabled issue_discards in LVM config"
echo ""
echo "To verify changes:"
cat "$BOOT_ENTRY"
echo ""
echo "⚠️  IMPORTANT: REBOOT REQUIRED"
echo ""
echo "After reboot, verify TRIM works:"
echo "  sudo fstrim -v /"
echo "  sudo fstrim -v /home"
echo ""
echo "If boot fails, use fallback entry and restore backup:"
echo "  sudo cp ${BOOT_ENTRY}.backup $BOOT_ENTRY"
echo ""
