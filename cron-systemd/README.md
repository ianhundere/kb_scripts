# Cron and Systemd Configuration

Backup scheduling and Timeshift automation for T14s.

## User Crontab

**crontab.example** - Example user crontab for Borg backups

Schedule:
- Home backup: Daily at 2 AM
- System backup: Daily at 3 AM
- Full drive backup: Weekly on Sunday at 4 AM

Install:
```bash
# Edit to add your credentials
nano crontab.example

# Install
crontab crontab.example

# Verify
crontab -l
```

## System Cron Jobs

**timeshift_hourly.cron** - Hourly Timeshift checks
- Runs every hour at 30 past
- Skips if Borg backup is running
- Install: `sudo cp timeshift_hourly.cron /etc/cron.d/timeshift_hourly`

**timeshift_boot.cron** - Timeshift on boot
- Creates snapshot 10 minutes after boot
- Skips if Borg backup is running
- Install: `sudo cp timeshift_boot.cron /etc/cron.d/timeshift_boot`

## Security - Recommended Approach

For better security, use the wrapper script method instead of inline credentials:

**Setup:**

1. Copy credentials file:
   ```bash
   cp ../borg_credentials.example ~/.borg_credentials
   nano ~/.borg_credentials  # Edit with your actual credentials
   chmod 600 ~/.borg_credentials
   ```

2. Install wrapper script:
   ```bash
   cp backup-wrapper.sh ~/bin/
   chmod +x ~/bin/backup-wrapper.sh
   ```

3. Install secure crontab:
   ```bash
   crontab crontab-secure.example
   ```

The wrapper script sources credentials from `~/.borg_credentials` (mode 600) and executes the backup script, keeping credentials out of crontab and backup scripts.

**Alternative:** Use `crontab.example` with inline credentials (simpler but less secure)

## Backup Scripts

The backup scripts in `~/bin/` now require environment variables:

- `BORG_PASSPHRASE` - Borg encryption passphrase
- `BORG_REPO` - Repository for home backups
- `BORG_REPO_SYS` - Repository for system backups
- `BORG_REPO_FULL` - Repository for full drive backups
- `BACKUP_DRIVE` - Path to external backup drive

Scripts will exit with an error if these are not set.
