#!/bin/bash
# Backup wrapper script for cron jobs
# Sources credentials from protected file and runs backup scripts
#
# Install:
# 1. Copy borg_credentials.example to ~/.borg_credentials
# 2. Edit ~/.borg_credentials with your actual credentials
# 3. chmod 600 ~/.borg_credentials
# 4. Copy this script to ~/bin/backup-wrapper.sh
# 5. chmod +x ~/bin/backup-wrapper.sh

set -euo pipefail

# Source credentials
CREDS_FILE="${HOME}/.borg_credentials"
if [ ! -f "$CREDS_FILE" ]; then
    echo "Error: $CREDS_FILE not found"
    echo "Copy borg_credentials.example to ~/.borg_credentials and edit it"
    exit 1
fi

# Check permissions
PERMS=$(stat -c %a "$CREDS_FILE")
if [ "$PERMS" != "600" ]; then
    echo "Error: $CREDS_FILE must have 600 permissions"
    echo "Run: chmod 600 ~/.borg_credentials"
    exit 1
fi

source "$CREDS_FILE"

# Run the backup script passed as argument
BACKUP_SCRIPT="$1"
if [ -z "$BACKUP_SCRIPT" ]; then
    echo "Usage: $0 <backup_script>"
    echo "Example: $0 backup_t14s_home"
    exit 1
fi

# Find the script in PATH
SCRIPT_PATH=$(which "$BACKUP_SCRIPT" 2>/dev/null || echo "$HOME/bin/$BACKUP_SCRIPT")
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Error: Backup script not found: $BACKUP_SCRIPT"
    exit 1
fi

# Run the backup script
exec "$SCRIPT_PATH"
