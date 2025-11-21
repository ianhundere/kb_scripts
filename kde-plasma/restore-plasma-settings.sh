#!/bin/bash
# Apply KDE Plasma Settings from Repository
# This script copies KDE Plasma configuration files from the repository to your config directory

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

echo -e "${GREEN}KDE Plasma Settings Installer${NC}"
echo "=============================="
echo ""
echo "This script will:"
echo "  1. Backup your current KDE config to: $BACKUP_DIR"
echo "  2. Copy KDE Plasma settings from this repository"
echo "  3. Replace template variables with your actual paths"
echo "  4. Restart plasmashell (optional)"
echo ""

# Ask for confirmation
read -p "Do you want to continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Installation cancelled.${NC}"
    exit 0
fi

# Create backup directory
echo -e "${GREEN}Creating backup...${NC}"
mkdir -p "$BACKUP_DIR"

# List of config files to backup and copy
CONFIG_FILES=(
    "plasma-org.kde.plasma.desktop-appletsrc"
    "plasmarc"
    "plasmashellrc"
    "kwinrc"
    "kwinoutputconfig.json"
    "kglobalshortcutsrc"
    "kxkbrc"
    "dolphinrc"
    "default.conf"
)

# Backup existing config files
for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$CONFIG_DIR/$file" ]; then
        echo "  Backing up $file"
        cp "$CONFIG_DIR/$file" "$BACKUP_DIR/"
    fi
done

# Backup konsole directory if it exists
if [ -d "$CONFIG_DIR/konsole" ]; then
    echo "  Backing up konsole directory"
    cp -r "$CONFIG_DIR/konsole" "$BACKUP_DIR/"
fi

echo -e "${GREEN}Backup complete: $BACKUP_DIR${NC}"
echo ""

# Copy and process config files
echo -e "${GREEN}Installing new configuration files...${NC}"
for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$SCRIPT_DIR/$file" ]; then
        echo "  Installing $file"
        # Replace $HOME and $USER with actual values
        sed -e "s|\$HOME|$HOME|g" -e "s|\$USER|$USER|g" "$SCRIPT_DIR/$file" > "$CONFIG_DIR/$file"
    fi
done

# Copy konsole directory if it exists
if [ -d "$SCRIPT_DIR/konsole" ]; then
    echo "  Installing konsole configuration"
    mkdir -p "$CONFIG_DIR/konsole"
    for file in "$SCRIPT_DIR/konsole"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            sed -e "s|\$HOME|$HOME|g" -e "s|\$USER|$USER|g" "$file" > "$CONFIG_DIR/konsole/$filename"
        fi
    done
fi

echo -e "${GREEN}Configuration files installed successfully!${NC}"
echo ""

# Ask if user wants to restart plasmashell
echo -e "${YELLOW}To apply changes, plasmashell needs to be restarted.${NC}"
read -p "Restart plasmashell now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Restarting plasmashell...${NC}"
    killall plasmashell 2>/dev/null || true
    sleep 2
    kstart5 plasmashell &
    echo -e "${GREEN}Plasmashell restarted!${NC}"
else
    echo -e "${YELLOW}Please restart plasmashell manually or log out and back in to apply changes.${NC}"
fi

echo ""
echo -e "${GREEN}Done!${NC}"
echo -e "Backup location: ${YELLOW}$BACKUP_DIR${NC}"
echo ""
echo "If you need to restore your old settings, run:"
echo "  cp $BACKUP_DIR/* $CONFIG_DIR/"
