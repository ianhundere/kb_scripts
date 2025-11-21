#!/bin/bash
# Backup Current KDE Plasma Settings to Repository
# This script copies your current KDE Plasma configuration files to the repository,
# replacing hardcoded paths with template variables

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the script directory (kde-plasma folder in repo)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$SCRIPT_DIR/backup-$(date +%Y%m%d-%H%M%S)"

echo -e "${GREEN}KDE Plasma Settings Backup Tool${NC}"
echo "================================"
echo ""
echo "This script will:"
echo "  1. Backup current repository settings to: $BACKUP_DIR"
echo "  2. Copy your current KDE config files to the repository"
echo "  3. Replace hardcoded paths with template variables (\$HOME, \$USER)"
echo "  4. Make files generic for sharing with others"
echo ""

# Ask for confirmation
read -p "Do you want to continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Backup cancelled.${NC}"
    exit 0
fi

# Create backup directory for old repo files
echo -e "${GREEN}Backing up existing repository files...${NC}"
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

# Backup existing repository files
for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$SCRIPT_DIR/$file" ]; then
        echo "  Backing up $file from repository"
        cp "$SCRIPT_DIR/$file" "$BACKUP_DIR/"
    fi
done

# Backup konsole directory from repo if it exists
if [ -d "$SCRIPT_DIR/konsole" ]; then
    echo "  Backing up konsole directory from repository"
    cp -r "$SCRIPT_DIR/konsole" "$BACKUP_DIR/"
fi

echo -e "${GREEN}Repository backup complete: $BACKUP_DIR${NC}"
echo ""

# Copy and process config files from system to repo
echo -e "${GREEN}Copying your current settings to repository...${NC}"
for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$CONFIG_DIR/$file" ]; then
        echo "  Copying $file"
        # Replace actual home path with $HOME variable and username with $USER
        sed -e "s|$HOME|\$HOME|g" -e "s|$USER|\$USER|g" "$CONFIG_DIR/$file" > "$SCRIPT_DIR/$file"
    else
        echo -e "  ${YELLOW}Skipping $file (not found in ~/.config)${NC}"
    fi
done

# Copy konsole directory if it exists
if [ -d "$CONFIG_DIR/konsole" ]; then
    echo "  Copying konsole configuration"
    mkdir -p "$SCRIPT_DIR/konsole"
    for file in "$CONFIG_DIR/konsole"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            echo "    - $filename"
            # Replace actual paths with variables
            sed -e "s|$HOME|\$HOME|g" -e "s|$USER|\$USER|g" "$file" > "$SCRIPT_DIR/konsole/$filename"
        fi
    done
fi

echo ""
echo -e "${GREEN}Settings backed up to repository successfully!${NC}"
echo ""
echo "Summary:"
echo "  - Your settings are now in: $SCRIPT_DIR"
echo "  - Old repository settings backed up to: $BACKUP_DIR"
echo "  - Hardcoded paths replaced with variables (\$HOME, \$USER)"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review the changes with: git diff"
echo "  2. Commit the updated settings if desired"
echo ""
echo "If you need to restore old repository files, run:"
echo "  cp $BACKUP_DIR/* $SCRIPT_DIR/"
