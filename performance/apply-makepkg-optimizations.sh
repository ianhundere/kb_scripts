#!/bin/bash
# Apply makepkg.conf optimizations for Ryzen 7 PRO 4750U
# This script patches /etc/makepkg.conf with CPU-specific optimizations

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Applying makepkg.conf optimizations...${NC}"

# Backup
if [[ ! -f /etc/makepkg.conf.backup ]]; then
    sudo cp /etc/makepkg.conf /etc/makepkg.conf.backup
    echo -e "${GREEN}✓ Backed up /etc/makepkg.conf${NC}"
fi

# Apply optimizations
sudo sed -i 's/-march=x86-64 -mtune=generic/-march=native -mtune=native/' /etc/makepkg.conf
echo -e "${GREEN}✓ Changed CFLAGS to use -march=native -mtune=native${NC}"

# Add MAKEFLAGS if not present
if ! grep -q "^MAKEFLAGS=" /etc/makepkg.conf; then
    sudo sed -i '/^#MAKEFLAGS=/a MAKEFLAGS="-j$(nproc)"' /etc/makepkg.conf
    echo -e "${GREEN}✓ Added MAKEFLAGS=\"-j\$(nproc)\" (parallel compilation)${NC}"
else
    echo -e "${YELLOW}⚠ MAKEFLAGS already set, skipping${NC}"
fi

echo -e "${GREEN}makepkg.conf optimizations applied!${NC}"
echo -e "${BLUE}Verify with: grep -E '^(CFLAGS|MAKEFLAGS)' /etc/makepkg.conf${NC}"
